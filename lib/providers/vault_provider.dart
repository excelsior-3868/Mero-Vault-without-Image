import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/vault_entry.dart';
import '../services/drive_service.dart';
import '../services/encryption_service.dart';

enum VaultStatus { initial, checking, notFound, found, unlocked, error }

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

  VaultProvider(this._driveService, this._encryptionService);

  Future<void> checkVaultExistence() async {
    _status = VaultStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = await _driveService.getVaultFile();
      if (file != null) {
        _fileId = file.id;
        _status = VaultStatus.found;
      } else {
        _fileId = null;
        _status = VaultStatus.notFound;
      }
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
    final salt = _encryptionService.generateSalt();
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
      print('Unlock failed: $e');
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
      print('Unlock with key failed: $e');
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

  Future<void> _saveToDrive(String? password) async {
    if (_vaultData == null) return;

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
      return;
    }

    final jsonString = jsonEncode(jsonMap);

    if (_fileId == null) {
      _fileId = await _driveService.createVault(jsonString);
    } else {
      await _driveService.updateVault(_fileId!, jsonString);
    }
  }

  bool verifyPassword(String password) {
    if (_salt == null || _derivedKey == null) return false;
    final testKey = _encryptionService.deriveKey(password, _salt!);
    return listEquals(testKey, _derivedKey);
  }

  String? get currentMasterKeyBase64 =>
      _derivedKey != null ? base64Encode(_derivedKey!) : null;

  Future<void> addEntry(VaultEntry entry, [String? password]) async {
    _vaultData?.entries.add(entry);
    notifyListeners();
    await _saveToDrive(password ?? _sessionPassword);
  }

  Future<void> updateEntry(VaultEntry updatedEntry, [String? password]) async {
    if (_vaultData == null) return;
    final index = _vaultData!.entries.indexWhere(
      (e) => e.id == updatedEntry.id,
    );
    if (index != -1) {
      _vaultData!.entries[index] = updatedEntry;
      notifyListeners();
      await _saveToDrive(password ?? _sessionPassword);
    }
  }

  Future<void> deleteEntry(String id, [String? password]) async {
    _vaultData?.entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveToDrive(password ?? _sessionPassword);
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
}
