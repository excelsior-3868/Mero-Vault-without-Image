# Bug Fix Implementation Plan

## Overview
This document provides step-by-step code changes to fix the critical bugs identified in the Mero Vault application.

---

## Fix #1: Update VaultData lastUpdated Timestamp

### File: `lib/providers/vault_provider.dart`

#### Change 1: Modify `addEntry` method (Lines 321-325)

**Before:**
```dart
Future<void> addEntry(VaultEntry entry, [String? password]) async {
  _vaultData?.entries.add(entry);
  notifyListeners();
  await _saveToDrive(password ?? _sessionPassword);
}
```

**After:**
```dart
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
```

#### Change 2: Modify `updateEntry` method (Lines 327-337)

**Before:**
```dart
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
```

**After:**
```dart
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
```

#### Change 3: Modify `deleteEntry` method (Lines 339-343)

**Before:**
```dart
Future<void> deleteEntry(String id, [String? password]) async {
  _vaultData?.entries.removeWhere((e) => e.id == id);
  notifyListeners();
  await _saveToDrive(password ?? _sessionPassword);
}
```

**After:**
```dart
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
```

---

## Fix #2: Add Error Handling to `_saveToDrive`

### File: `lib/providers/vault_provider.dart`

#### Change: Modify `_saveToDrive` method (Lines 254-310)

**Before:**
```dart
Future<void> _saveToDrive(String? password) async {
  if (_vaultData == null) return;
  
  // ... encryption logic ...
  
  final jsonString = jsonEncode(jsonMap);

  if (_fileId == null) {
    _fileId = await _driveService.createVault(jsonString);
  } else {
    await _driveService.updateVault(_fileId!, jsonString);
  }
}
```

**After:**
```dart
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
```

---

## Fix #3: Update UI to Handle Save Failures

### File: `lib/features/home/add_entry_screen.dart`

#### Change: Modify `_save` method (Lines 106-158)

**Before:**
```dart
await provider.addEntry(entry);

if (mounted) {
  Navigator.pop(context);
  ToastNotification.show(
    context,
    widget.entryToEdit != null
        ? 'Entry updated successfully'
        : 'Entry saved to vault',
  );
}
```

**After:**
```dart
final success = widget.entryToEdit != null
    ? await provider.updateEntry(updatedEntry)
    : await provider.addEntry(entry);

if (mounted) {
  if (success) {
    Navigator.pop(context);
    ToastNotification.show(
      context,
      widget.entryToEdit != null
          ? 'Entry updated successfully'
          : 'Entry saved to vault',
    );
  } else {
    ToastNotification.show(
      context,
      'Failed to save entry. Please check your internet connection and try again.',
      isError: true,
    );
  }
}
```

### File: `lib/features/home/entry_detail_screen.dart`

Find the delete method and update similarly:

**Before:**
```dart
await vaultProvider.deleteEntry(widget.entry.id);
if (mounted) {
  Navigator.pop(context);
  ToastNotification.show(context, 'Entry deleted');
}
```

**After:**
```dart
final success = await vaultProvider.deleteEntry(widget.entry.id);
if (mounted) {
  if (success) {
    Navigator.pop(context);
    ToastNotification.show(context, 'Entry deleted');
  } else {
    ToastNotification.show(
      context,
      'Failed to delete entry. Please check your internet connection.',
      isError: true,
    );
  }
}
```

---

## Fix #4: Improve DriveService Error Handling

### File: `lib/services/drive_service.dart`

#### Change: Modify `updateVault` method (Lines 100-116)

**Before:**
```dart
Future<bool> updateVault(String fileId, String content) async {
  final api = await _api;
  if (api == null) return false;

  try {
    final uploadMedia = drive.Media(
      Stream.value(utf8.encode(content)),
      utf8.encode(content).length,
    );

    await api.files.update(drive.File(), fileId, uploadMedia: uploadMedia);
    return true;
  } catch (e) {
    print('Error updating vault: $e');
    return false;
  }
}
```

**After:**
```dart
Future<bool> updateVault(String fileId, String content) async {
  final api = await _api;
  if (api == null) {
    print('Error updating vault: Drive API not initialized');
    throw Exception('Drive API not available. Please check your internet connection.');
  }

  try {
    final uploadMedia = drive.Media(
      Stream.value(utf8.encode(content)),
      utf8.encode(content).length,
    );

    await api.files.update(drive.File(), fileId, uploadMedia: uploadMedia);
    print('Vault updated successfully on Drive');
    return true;
  } catch (e) {
    print('Error updating vault: $e');
    // Provide more specific error information
    if (e.toString().contains('SocketException') || 
        e.toString().contains('NetworkException')) {
      throw Exception('Network error: Please check your internet connection');
    } else if (e.toString().contains('404')) {
      throw Exception('Vault file not found on Drive');
    } else if (e.toString().contains('403')) {
      throw Exception('Permission denied: Please re-authenticate');
    } else {
      throw Exception('Failed to update vault: $e');
    }
  }
}
```

#### Change: Modify `createVault` method (Lines 75-98)

**Before:**
```dart
Future<String?> createVault(String initialContent) async {
  final api = await _api;
  if (api == null) return null;

  try {
    // ... creation logic ...
    return file.id;
  } catch (e) {
    print('Error creating vault: $e');
    return null;
  }
}
```

**After:**
```dart
Future<String?> createVault(String initialContent) async {
  final api = await _api;
  if (api == null) {
    print('Error creating vault: Drive API not initialized');
    throw Exception('Drive API not available. Please check your internet connection.');
  }

  try {
    final uploadMedia = drive.Media(
      Stream.value(utf8.encode(initialContent)),
      utf8.encode(initialContent).length,
    );

    final fileToUpload = drive.File()
      ..name = _fileName
      ..parents = ['appDataFolder'];

    final file = await api.files.create(
      fileToUpload,
      uploadMedia: uploadMedia,
    );
    
    print('Vault created successfully with ID: ${file.id}');
    return file.id;
  } catch (e) {
    print('Error creating vault: $e');
    if (e.toString().contains('SocketException') || 
        e.toString().contains('NetworkException')) {
      throw Exception('Network error: Please check your internet connection');
    } else {
      throw Exception('Failed to create vault: $e');
    }
  }
}
```

---

## Fix #5: Ensure Proper Vault State Reset

### File: `lib/main.dart`

#### Change: Update `didChangeAppLifecycleState` (Lines 41-48)

**Before:**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive) {
    // Auto-lock the vault when app goes to background
    final provider = Provider.of<VaultProvider>(context, listen: false);
    provider.clear();
  }
}
```

**After:**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive) {
    // Auto-lock the vault when app goes to background
    try {
      final provider = Provider.of<VaultProvider>(context, listen: false);
      provider.clear();
      if (kDebugMode) print('Vault cleared on app background');
    } catch (e) {
      if (kDebugMode) print('Error clearing vault: $e');
    }
  }
}
```

### File: `lib/services/auth_service.dart`

#### Change: Ensure clean state on sign out (Lines 79-91)

**Before:**
```dart
Future<void> signOut() async {
  _manuallyLoggedOut = true;
  _currentUser = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_logged_in', false);

  try {
    await _googleSignIn.disconnect();
  } catch (e) {
    await _googleSignIn.signOut();
  }
  notifyListeners();
}
```

**After:**
```dart
Future<void> signOut() async {
  _manuallyLoggedOut = true;
  _currentUser = null;
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_logged_in', false);
  
  // Clear any cached data
  await prefs.remove('last_vault_check');
  await prefs.remove('cached_file_id');

  try {
    await _googleSignIn.disconnect();
  } catch (e) {
    if (kDebugMode) print('Disconnect failed, trying signOut: $e');
    await _googleSignIn.signOut();
  }
  
  if (kDebugMode) print('User signed out successfully');
  notifyListeners();
}
```

---

## Fix #6: Add Vault Existence Check Debouncing

### File: `lib/providers/vault_provider.dart`

#### Add new field:
```dart
DateTime? _lastVaultCheck;
static const Duration _vaultCheckCooldown = Duration(seconds: 5);
```

#### Modify `checkVaultExistence` method:

**Before:**
```dart
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
```

**After:**
```dart
Future<void> checkVaultExistence({bool force = false}) async {
  // Prevent rapid repeated checks
  if (!force && _lastVaultCheck != null) {
    final timeSinceLastCheck = DateTime.now().difference(_lastVaultCheck!);
    if (timeSinceLastCheck < _vaultCheckCooldown) {
      if (kDebugMode) {
        print('Skipping vault check (cooldown: ${_vaultCheckCooldown.inSeconds - timeSinceLastCheck.inSeconds}s remaining)');
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
```

---

## Testing Checklist

After implementing these fixes, test the following scenarios:

### ✅ Test 1: Normal Operation
- [ ] Add 20 entries
- [ ] Log out
- [ ] Log back in
- [ ] Verify all 20 entries are present

### ✅ Test 2: Network Interruption
- [ ] Add 5 entries
- [ ] Turn off WiFi/Mobile data
- [ ] Try to add 5 more entries
- [ ] Verify error messages are shown
- [ ] Turn on internet
- [ ] Retry adding entries
- [ ] Log out and log in
- [ ] Verify only successfully saved entries are present

### ✅ Test 3: Rapid Operations
- [ ] Add 10 entries rapidly (within 10 seconds)
- [ ] Immediately log out
- [ ] Log back in
- [ ] Verify all 10 entries are present

### ✅ Test 4: Update and Delete
- [ ] Add 5 entries
- [ ] Update 2 entries
- [ ] Delete 1 entry
- [ ] Log out and log in
- [ ] Verify changes persisted correctly

### ✅ Test 5: Account Switching
- [ ] Login with Account A
- [ ] Create vault with 10 entries
- [ ] Sign out
- [ ] Login with Account B
- [ ] Verify "Create New Vault" screen appears
- [ ] Create vault with 5 entries
- [ ] Sign out
- [ ] Login with Account A
- [ ] Verify Account A's 10 entries are intact

---

## Deployment Steps

1. **Backup Current Code**
   ```bash
   git add .
   git commit -m "Backup before bug fixes"
   git branch backup-before-fixes
   ```

2. **Apply Fixes**
   - Apply changes in order: Fix #1 → Fix #2 → Fix #3 → Fix #4 → Fix #5 → Fix #6

3. **Test Locally**
   - Run all test cases from the Testing Checklist

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "Fix: Data persistence and vault initialization bugs

   - Update lastUpdated timestamp on all entry modifications
   - Add error handling and rollback for failed saves
   - Improve DriveService error reporting
   - Add vault check debouncing
   - Ensure proper state cleanup on sign out"
   ```

5. **Deploy**
   - Build and test on all target platforms
   - Monitor for any new issues

---

## Additional Recommendations

### 1. Add Logging Service
Create a proper logging service instead of using `print()` statements:

```dart
class LogService {
  static void info(String message) {
    if (kDebugMode) print('[INFO] $message');
  }
  
  static void error(String message, [dynamic error]) {
    if (kDebugMode) print('[ERROR] $message${error != null ? ': $error' : ''}');
  }
  
  static void warning(String message) {
    if (kDebugMode) print('[WARN] $message');
  }
}
```

### 2. Add Retry Mechanism
Implement exponential backoff for Drive operations:

```dart
Future<T?> retryOperation<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  Duration delay = initialDelay;
  
  while (attempt < maxAttempts) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts) rethrow;
      
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
    }
  }
  return null;
}
```

### 3. Add Data Integrity Verification
Add checksums to verify data integrity:

```dart
String calculateChecksum(String data) {
  return sha256.convert(utf8.encode(data)).toString();
}
```

---

## Conclusion

These fixes address the root causes of:
1. **Entries vanishing** - by ensuring `lastUpdated` is properly maintained and saves are verified
2. **Vault state reset** - by improving state management and error handling

The changes maintain backward compatibility while significantly improving reliability and user experience.
