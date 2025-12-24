import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/vault_entry.dart';
import '../services/drive_service.dart';
import '../services/encryption_service.dart';
// import 'package:encrypt/encrypt.dart' as encrypt_lib;

class VaultProvider extends ChangeNotifier {
  final DriveService _driveService;
  final EncryptionService _encryptionService;
  
  VaultData? _vaultData;
  VaultData? get vaultData => _vaultData;
  
  String? _masterPassword; // Kept in memory only for the session
  bool get isUnlocked => _vaultData != null && _masterPassword != null;
  
  String? _fileId;

  VaultProvider(this._driveService, this._encryptionService);

  // Transform the in-memory (cleartext) data to the encrypted JSON format required for storage
  Map<String, dynamic> _toEncryptedJson(VaultData data) {
    return {
      'vault_meta': {
        'version': data.version,
        'encryption': 'AES-256-GCM',
        'last_updated': data.lastUpdated.toIso8601String(),
      },
      'entries': data.entries.map((e) {
        // ID and Title are kept cleartext for indexing/listing
        // Fields values are encrypted
        final encryptedFields = e.fields.map((f) {
           return {
             'label': f.label,
             'value': _encryptionService.encrypt(f.value, _masterPassword!), // Encrypt value
             'is_obscured': f.isObscured,
           };
        }).toList();

        return {
          'id': e.id,
          'title': e.title,
          'fields': encryptedFields,
          'created_at': e.createdAt.toIso8601String(),
          'updated_at': e.updatedAt.toIso8601String(),
        };
      }).toList(),
    };
  }

  // Transform the storage JSON (encrypted) to in-memory (cleartext) data
  VaultData _fromEncryptedJson(Map<String, dynamic> json) {
    final meta = json['vault_meta'] as Map<String, dynamic>? ?? {};
    final entriesList = json['entries'] as List<dynamic>? ?? [];
    
    final entries = entriesList.map((e) {
      final map = e as Map<String, dynamic>;
      final fieldsList = <VaultField>[];

      // Handle dynamic fields
      if (map['fields'] != null) {
        final list = map['fields'] as List<dynamic>;
        for (var item in list) {
          final fMap = item as Map<String, dynamic>;
          String decryptedValue = '';
          try {
             decryptedValue = _encryptionService.decrypt(fMap['value'] as String, _masterPassword!);
          } catch (_) {
             decryptedValue = 'Error';
          }

          fieldsList.add(VaultField(
            label: fMap['label'] as String,
            value: decryptedValue,
            isObscured: fMap['is_obscured'] as bool? ?? false,
          ));
        }
      } else {
        // Fallback or migration for old schema if it exists in the wild (though we just changed it)
        // If code runs against old file, the file has keys like 'password'.
        
        // Decrypt legacy keys if present
        if (map.containsKey('username')) {
           fieldsList.add(VaultField(label: 'Username', value: map['username'] as String));
        }
        if (map.containsKey('password')) {
           String decryptedPwd = '';
           try {
              decryptedPwd = _encryptionService.decrypt(map['password'] as String, _masterPassword!);
           } catch (_) { decryptedPwd = 'Error'; }
           fieldsList.add(VaultField(label: 'Password', value: decryptedPwd, isObscured: true));
        }
        if (map.containsKey('url')) {
           fieldsList.add(VaultField(label: 'URL', value: map['url'] as String));
        }
        if (map.containsKey('notes')) {
           String decryptedNotes = '';
           try {
              if (map['notes'] != null) {
                 decryptedNotes = _encryptionService.decrypt(map['notes'] as String, _masterPassword!);
              }
           } catch (_) {}
           if (decryptedNotes.isNotEmpty) {
             fieldsList.add(VaultField(label: 'Notes', value: decryptedNotes));
           }
        }
      }

      return VaultEntry(
        id: map['id'] as String,
        title: map['title'] as String,
        fields: fieldsList,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String? ?? map['created_at'] as String),
      );
    }).toList();

    return VaultData(
      version: meta['version'] as String? ?? '1.2',
      lastUpdated: meta['last_updated'] != null 
          ? DateTime.parse(meta['last_updated'] as String) 
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

      // Temporary set password to attempt decryption
      _masterPassword = password;
      
      final Map<String, dynamic> jsonRoot = jsonDecode(encryptedContent);
      _vaultData = _fromEncryptedJson(jsonRoot);

      notifyListeners();
      return true;
      
    } catch (e) {
      print('Unlock failed: $e');
      _masterPassword = null;
      return false;
    }
  }

  Future<void> createNewVault(String password) async {
    _masterPassword = password;
    
    final now = DateTime.now().toUtc();
    final emptyData = VaultData(
      version: '1.2',
      lastUpdated: now,
      entries: [],
    );
    
    _vaultData = emptyData;
    await _saveToDrive();
  }
  
  Future<void> _saveToDrive() async {
    if (_vaultData == null || _masterPassword == null) return;
    
    final jsonMap = _toEncryptedJson(_vaultData!);
    final jsonString = jsonEncode(jsonMap);
    
    // Save to Drive
    if (_fileId == null) {
       _fileId = await _driveService.createVault(jsonString);
    } else {
       // TODO: Update file content (createVault actually creates new file, need update method in DriveService)
       // For now, assume create updates if possible or we accept multiples (Drive allows it).
       //Ideally we should update.
       _fileId = await _driveService.createVault(jsonString); 
    }
  }

  Future<void> addEntry(VaultEntry entry) async {
    _vaultData?.entries.add(entry);
    notifyListeners();
    await _saveToDrive();
  }

  Future<void> updateEntry(VaultEntry updatedEntry) async {
    if (_vaultData == null) return;
    final index = _vaultData!.entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _vaultData!.entries[index] = updatedEntry;
      notifyListeners();
      await _saveToDrive();
    }
  }

  Future<void> deleteEntry(String id) async {
    _vaultData?.entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveToDrive();
  }

}
