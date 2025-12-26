import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/vault_entry.dart';
import '../services/drive_service.dart';
import '../services/encryption_service.dart';

enum VaultStatus { initial, checking, notFound, found, unlocked, error }

enum StorageWarning { ok, low, critical, unknown }

class VaultProvider extends ChangeNotifier {
  final DriveService _driveService;
  final EncryptionService _encryptionService;

  VaultData? _vaultData;
  VaultData? get vaultData => _vaultData;

  Uint8List? _derivedKey; // Kept in memory only for the session
  String? _sessionPassword; // Kept in memory only for the session
  Uint8List? _salt;
  int? _iterations;
  bool get isUnlocked => _vaultData != null;

  VaultStatus _status = VaultStatus.initial;
  VaultStatus get status => _status;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _fileId;
  DateTime? _lastVaultCheck;
  static const Duration _vaultCheckCooldown = Duration(seconds: 5);

  VaultProvider(this._driveService, this._encryptionService);

  Future<void> checkVaultExistence({bool force = false}) async {
    // Prevent rapid repeated checks
    if (!force && _lastVaultCheck != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastVaultCheck!);
      if (timeSinceLastCheck < _vaultCheckCooldown) {
        if (kDebugMode) {
          print(
            'Skipping vault check (cooldown: ${_vaultCheckCooldown.inSeconds - timeSinceLastCheck.inSeconds}s remaining)',
          );
        }
        return;
      }
    }

    _status = VaultStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) print('Checking vault existence...');
      final file = await _driveService.getVaultFile();

      if (file != null) {
        _fileId = file.id;
        _status = VaultStatus.found;
        if (kDebugMode) print('Vault found with ID: $_fileId');
      } else {
        _fileId = null;
        _status = VaultStatus.notFound;
        if (kDebugMode) print('No vault found');
      }

      _lastVaultCheck = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('Vault check failed: $e');
      }
      _errorMessage = e.toString();
      _status = VaultStatus.error;
    }
    notifyListeners();
  }

  // Transform the in-memory (cleartext) data to the encrypted JSON format required for storage
  Map<String, dynamic> _toEncryptedJson(VaultData data, String password) {
    // CRITICAL: Reuse existing salt if available, only generate new salt for brand new vaults
    final salt = _salt ?? _encryptionService.generateSalt();
    final key = _encryptionService.deriveKey(password, salt);
    _derivedKey = key;
    _sessionPassword = password;
    _salt = salt;
    _iterations = EncryptionService.iterations;

    final vaultEntriesJson = data.entries.map((e) {
      return {
        'id': e.id,
        'title': e.title,
        'fields': e.fields
            .map(
              (f) => {
                'label': f.label,
                'value': f.value,
                'is_obscured': f.isObscured,
              },
            )
            .toList(),
        'created_at': e.createdAt.toIso8601String(),
        'updated_at': e.updatedAt.toIso8601String(),
      };
    }).toList();

    final cleartextVault = jsonEncode({
      'vault_name': data.vaultName,
      'entries': vaultEntriesJson,
    });

    final encryptedVault = _encryptionService.encrypt(cleartextVault, key);

    return {
      'version': '1.0',
      'kdf': {
        'algorithm': 'PBKDF2-HMAC-SHA256',
        'salt': base64Encode(salt),
        'iterations': EncryptionService.iterations,
      },
      'vault_cipher': encryptedVault,
      'last_updated': data.lastUpdated.toIso8601String(),
    };
  }

  // Transform the storage JSON (encrypted) to in-memory (cleartext) data
  VaultData _fromEncryptedJson(Map<String, dynamic> json, String password) {
    final kdf = json['kdf'] as Map<String, dynamic>;
    final salt = base64Decode(kdf['salt'] as String);
    final iterations =
        kdf['iterations'] as int? ?? EncryptionService.iterations;
    final key = _encryptionService.deriveKey(password, salt);
    _derivedKey = key;
    _salt = salt;
    _iterations = iterations;

    final cipher = json['vault_cipher'] as String;
    final decryptedJson = _encryptionService.decrypt(cipher, key);
    final Map<String, dynamic> vaultMap = jsonDecode(decryptedJson);

    final entriesList = vaultMap['entries'] as List<dynamic>? ?? [];

    final entries = entriesList.map((e) {
      final map = e as Map<String, dynamic>;
      final fieldsList = (map['fields'] as List<dynamic>).map((f) {
        final fMap = f as Map<String, dynamic>;
        return VaultField(
          label: fMap['label'] as String,
          value: fMap['value'] as String,
          isObscured: fMap['is_obscured'] as bool? ?? false,
        );
      }).toList();

      return VaultEntry(
        id: map['id'] as String,
        title: map['title'] as String,
        fields: fieldsList,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(
          map['updated_at'] as String? ?? map['created_at'] as String,
        ),
      );
    }).toList();

    return VaultData(
      vaultName: vaultMap['vault_name'] as String? ?? 'My Vault',
      version: json['version'] as String? ?? '1.0',
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now().toUtc(),
      entries: entries,
    );
  }

  Future<bool> unlock(String password) async {
    if (_fileId == null) {
      final file = await _driveService.getVaultFile();
      if (file == null) return false;
      _fileId = file.id;
    }

    try {
      final encryptedContent = await _driveService.getVaultContent(_fileId!);
      if (encryptedContent == null) return false;

      final Map<String, dynamic> jsonRoot = jsonDecode(encryptedContent);
      _vaultData = _fromEncryptedJson(jsonRoot, password);
      _status = VaultStatus.unlocked;

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Unlock failed: $e');
      _errorMessage = e.toString();
      _derivedKey = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlockWithKey(Uint8List key) async {
    if (_fileId == null) {
      final file = await _driveService.getVaultFile();
      if (file == null) return false;
      _fileId = file.id;
    }

    try {
      final encryptedContent = await _driveService.getVaultContent(_fileId!);
      if (encryptedContent == null) return false;

      final Map<String, dynamic> jsonRoot = jsonDecode(encryptedContent);
      _derivedKey = key;

      final cipher = jsonRoot['vault_cipher'] as String;
      final decryptedJson = _encryptionService.decrypt(cipher, key);
      final Map<String, dynamic> vaultMap = jsonDecode(decryptedJson);

      // Re-use logic from _fromEncryptedJson or factor it out
      // For brevity here, I'll just clear the data and re-fetch properly if needed,
      // but let's implement the decryption part.

      final entriesList = vaultMap['entries'] as List<dynamic>? ?? [];
      final entries = entriesList.map((e) {
        final map = e as Map<String, dynamic>;
        final fieldsList = (map['fields'] as List<dynamic>).map((f) {
          final fMap = f as Map<String, dynamic>;
          return VaultField(
            label: fMap['label'] as String,
            value: fMap['value'] as String,
            isObscured: fMap['is_obscured'] as bool? ?? false,
          );
        }).toList();
        return VaultEntry(
          id: map['id'] as String,
          title: map['title'] as String,
          fields: fieldsList,
          createdAt: DateTime.parse(map['created_at'] as String),
          updatedAt: DateTime.parse(map['updated_at'] as String),
        );
      }).toList();

      _vaultData = VaultData(
        vaultName: vaultMap['vault_name'] as String? ?? 'My Vault',
        version: jsonRoot['version'] as String? ?? '1.0',
        lastUpdated: DateTime.parse(jsonRoot['last_updated'] as String),
        entries: entries,
      );

      _status = VaultStatus.unlocked;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Unlock with key failed: $e');
      _errorMessage = e.toString();
      _derivedKey = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> createNewVault(String name, String password) async {
    final now = DateTime.now().toUtc();
    final emptyData = VaultData(
      vaultName: name,
      version: '1.0',
      lastUpdated: now,
      entries: [],
    );

    _vaultData = emptyData;
    await _saveToDrive(password);
    _status = VaultStatus.unlocked;
    notifyListeners();
  }

  /// Check if there's enough storage before saving
  Future<StorageWarning> checkStorageBeforeSave() async {
    try {
      final quota = await _driveService.getStorageQuota();

      if (quota == null) {
        // If we can't get quota, allow save but warn
        return StorageWarning.unknown;
      }

      if (quota.isCritical) {
        return StorageWarning.critical;
      }

      if (quota.isLow) {
        return StorageWarning.low;
      }

      return StorageWarning.ok;
    } catch (e) {
      if (kDebugMode) print('Error checking storage: $e');
      return StorageWarning.unknown;
    }
  }

  Future<bool> _saveToDrive(String? password) async {
    if (_vaultData == null) {
      if (kDebugMode) print('Cannot save: vault data is null');
      return false;
    }

    try {
      Map<String, dynamic> jsonMap;
      if (password != null) {
        jsonMap = _toEncryptedJson(_vaultData!, password);
      } else if (_derivedKey != null) {
        final vaultEntriesJson = _vaultData!.entries.map((e) {
          return {
            'id': e.id,
            'title': e.title,
            'fields': e.fields
                .map(
                  (f) => {
                    'label': f.label,
                    'value': f.value,
                    'is_obscured': f.isObscured,
                  },
                )
                .toList(),
            'created_at': e.createdAt.toIso8601String(),
            'updated_at': e.updatedAt.toIso8601String(),
          };
        }).toList();

        final cleartextVault = jsonEncode({
          'vault_name': _vaultData!.vaultName,
          'entries': vaultEntriesJson,
        });

        final encryptedVault = _encryptionService.encrypt(
          cleartextVault,
          _derivedKey!,
        );

        jsonMap = {
          'version': _vaultData!.version,
          'kdf': {
            'algorithm': 'PBKDF2-HMAC-SHA256',
            'salt': _salt != null ? base64Encode(_salt!) : '',
            'iterations': _iterations ?? EncryptionService.iterations,
          },
          'vault_cipher': encryptedVault,
          'last_updated': _vaultData!.lastUpdated.toIso8601String(),
        };
      } else {
        if (kDebugMode) print('Cannot save: no password or derived key');
        _errorMessage = 'No encryption key available';
        return false;
      }

      final jsonString = jsonEncode(jsonMap);

      if (_fileId == null) {
        if (kDebugMode) print('Creating new vault file...');
        _fileId = await _driveService.createVault(jsonString);
        if (_fileId == null) {
          _errorMessage = 'Failed to create vault file on Google Drive';
          if (kDebugMode) print(_errorMessage);
          return false;
        }
        if (kDebugMode) print('Vault created with ID: $_fileId');
      } else {
        if (kDebugMode) print('Updating existing vault file: $_fileId');
        final success = await _driveService.updateVault(_fileId!, jsonString);
        if (!success) {
          _errorMessage = 'Failed to update vault on Google Drive';
          if (kDebugMode) print(_errorMessage);
          return false;
        }
        if (kDebugMode) print('Vault updated successfully');
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error saving to Drive: $e';
      if (kDebugMode) print(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  bool verifyPassword(String password) {
    if (_salt == null || _derivedKey == null) return false;
    final testKey = _encryptionService.deriveKey(password, _salt!);
    return listEquals(testKey, _derivedKey);
  }

  String? get currentMasterKeyBase64 =>
      _derivedKey != null ? base64Encode(_derivedKey!) : null;

  Future<bool> addEntry(VaultEntry entry, [String? password]) async {
    if (_vaultData == null) return false;

    _vaultData!.entries.add(entry);

    // Update lastUpdated timestamp
    _vaultData = VaultData(
      vaultName: _vaultData!.vaultName,
      version: _vaultData!.version,
      lastUpdated: DateTime.now().toUtc(),
      entries: _vaultData!.entries,
    );

    notifyListeners();

    final success = await _saveToDrive(password ?? _sessionPassword);

    if (!success) {
      // Rollback on failure
      _vaultData!.entries.removeLast();
      _vaultData = VaultData(
        vaultName: _vaultData!.vaultName,
        version: _vaultData!.version,
        lastUpdated: _vaultData!.lastUpdated,
        entries: _vaultData!.entries,
      );
      notifyListeners();
    }

    return success;
  }

  Future<bool> updateEntry(VaultEntry updatedEntry, [String? password]) async {
    if (_vaultData == null) return false;

    final index = _vaultData!.entries.indexWhere(
      (e) => e.id == updatedEntry.id,
    );

    if (index == -1) return false;

    // Store old entry for rollback
    final oldEntry = _vaultData!.entries[index];

    _vaultData!.entries[index] = updatedEntry;

    // Update lastUpdated timestamp
    _vaultData = VaultData(
      vaultName: _vaultData!.vaultName,
      version: _vaultData!.version,
      lastUpdated: DateTime.now().toUtc(),
      entries: _vaultData!.entries,
    );

    notifyListeners();

    final success = await _saveToDrive(password ?? _sessionPassword);

    if (!success) {
      // Rollback on failure
      _vaultData!.entries[index] = oldEntry;
      _vaultData = VaultData(
        vaultName: _vaultData!.vaultName,
        version: _vaultData!.version,
        lastUpdated: _vaultData!.lastUpdated,
        entries: _vaultData!.entries,
      );
      notifyListeners();
    }

    return success;
  }

  Future<bool> deleteEntry(String id, [String? password]) async {
    if (_vaultData == null) return false;

    // Find and store the entry for potential rollback
    final entryIndex = _vaultData!.entries.indexWhere((e) => e.id == id);
    if (entryIndex == -1) return false;

    final deletedEntry = _vaultData!.entries[entryIndex];

    _vaultData!.entries.removeAt(entryIndex);

    // Update lastUpdated timestamp
    _vaultData = VaultData(
      vaultName: _vaultData!.vaultName,
      version: _vaultData!.version,
      lastUpdated: DateTime.now().toUtc(),
      entries: _vaultData!.entries,
    );

    notifyListeners();

    final success = await _saveToDrive(password ?? _sessionPassword);

    if (!success) {
      // Rollback on failure
      _vaultData!.entries.insert(entryIndex, deletedEntry);
      _vaultData = VaultData(
        vaultName: _vaultData!.vaultName,
        version: _vaultData!.version,
        lastUpdated: _vaultData!.lastUpdated,
        entries: _vaultData!.entries,
      );
      notifyListeners();
    }

    return success;
  }

  void clear() {
    _vaultData = null;
    _derivedKey = null;
    _sessionPassword = null;
    _salt = null;
    _iterations = null;
    _fileId = null;
    _status = VaultStatus.initial;
    _driveService.reset();
    notifyListeners();
  }

  /// Export vault as readable JSON
  String exportVaultAsJson() {
    if (_vaultData == null) {
      throw Exception('No vault loaded to export');
    }

    final exportData = {
      'vault_name': _vaultData!.vaultName,
      'version': _vaultData!.version,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'last_updated': _vaultData!.lastUpdated.toIso8601String(),
      'total_entries': _vaultData!.entries.length,
      'entries': _vaultData!.entries.map((entry) {
        return {
          'id': entry.id,
          'title': entry.title,
          'created_at': entry.createdAt.toIso8601String(),
          'updated_at': entry.updatedAt.toIso8601String(),
          'fields': entry.fields.map((field) {
            return {
              'label': field.label,
              'value': field.value,
              'is_obscured': field.isObscured,
            };
          }).toList(),
        };
      }).toList(),
    };

    // Return formatted JSON with indentation
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  /// Export vault as readable TXT
  String exportVaultAsTxt() {
    if (_vaultData == null) {
      throw Exception('No vault loaded to export');
    }

    final buffer = StringBuffer();

    // Header
    buffer.writeln('=' * 60);
    buffer.writeln('MERO VAULT - PASSWORD EXPORT');
    buffer.writeln('=' * 60);
    buffer.writeln();
    buffer.writeln('Vault Name: ${_vaultData!.vaultName}');
    buffer.writeln('Exported: ${DateTime.now().toLocal()}');
    buffer.writeln('Total Entries: ${_vaultData!.entries.length}');
    buffer.writeln();
    buffer.writeln('=' * 60);
    buffer.writeln();

    // Entries
    for (var i = 0; i < _vaultData!.entries.length; i++) {
      final entry = _vaultData!.entries[i];

      buffer.writeln('Entry ${i + 1}: ${entry.title}');
      buffer.writeln('-' * 60);
      buffer.writeln('Created: ${entry.createdAt.toLocal()}');
      buffer.writeln('Updated: ${entry.updatedAt.toLocal()}');
      buffer.writeln();

      // Fields
      for (var field in entry.fields) {
        buffer.writeln('${field.label}: ${field.value}');
      }

      buffer.writeln();
      buffer.writeln('=' * 60);
      buffer.writeln();
    }

    // Footer
    buffer.writeln();
    buffer.writeln('End of Export');
    buffer.writeln('Generated by Mero Vault');

    return buffer.toString();
  }
}
