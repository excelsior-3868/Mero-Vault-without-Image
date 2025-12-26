# Bug Analysis Report - Mero Vault
**Date:** 2025-12-26  
**Reported Issues:**
1. Entries vanishing after re-login (5-10 out of 20 entries lost)
2. Vault state reset - showing "Create New Vault" screen on subsequent logins

---

## 🔴 CRITICAL BUGS IDENTIFIED

### **Bug #1: Missing `lastUpdated` Update in VaultData**
**Severity:** CRITICAL  
**Location:** `lib/providers/vault_provider.dart`

#### Problem:
When adding, updating, or deleting entries, the `VaultData.lastUpdated` field is **NOT being updated**. This field remains at the original vault creation time.

#### Impact:
- Google Drive may not recognize the file has changed
- Potential sync conflicts
- Data loss when multiple devices or sessions are involved

#### Current Code Issue:
```dart
// In addEntry, updateEntry, deleteEntry methods
Future<void> addEntry(VaultEntry entry, [String? password]) async {
  _vaultData?.entries.add(entry);
  notifyListeners();
  await _saveToDrive(password ?? _sessionPassword);
  // ❌ _vaultData.lastUpdated is NEVER updated!
}
```

#### Fix Required:
Update `lastUpdated` before saving:
```dart
Future<void> addEntry(VaultEntry entry, [String? password]) async {
  if (_vaultData == null) return;
  _vaultData!.entries.add(entry);
  // ✅ Update lastUpdated timestamp
  _vaultData = VaultData(
    vaultName: _vaultData!.vaultName,
    version: _vaultData!.version,
    lastUpdated: DateTime.now().toUtc(),
    entries: _vaultData!.entries,
  );
  notifyListeners();
  await _saveToDrive(password ?? _sessionPassword);
}
```

---

### **Bug #2: Race Condition in `_saveToDrive`**
**Severity:** HIGH  
**Location:** `lib/providers/vault_provider.dart` - Line 254-310

#### Problem:
The `_saveToDrive` method is **async** but has **no error handling** or **retry mechanism**. If the save fails silently:
- User sees "Entry saved" toast
- Data is NOT actually saved to Google Drive
- On next login, entries are missing

#### Current Code Issues:
```dart
Future<void> _saveToDrive(String? password) async {
  if (_vaultData == null) return;
  
  // ... encryption logic ...
  
  if (_fileId == null) {
    _fileId = await _driveService.createVault(jsonString);
  } else {
    await _driveService.updateVault(_fileId!, jsonString);
    // ❌ No error checking if update failed!
    // ❌ No retry mechanism
    // ❌ No user notification on failure
  }
}
```

#### Fix Required:
Add proper error handling and verification:
```dart
Future<bool> _saveToDrive(String? password) async {
  if (_vaultData == null) return false;
  
  try {
    // ... encryption logic ...
    
    if (_fileId == null) {
      _fileId = await _driveService.createVault(jsonString);
      if (_fileId == null) {
        throw Exception('Failed to create vault file');
      }
    } else {
      final success = await _driveService.updateVault(_fileId!, jsonString);
      if (!success) {
        throw Exception('Failed to update vault');
      }
    }
    return true;
  } catch (e) {
    print('Error saving to Drive: $e');
    _errorMessage = 'Failed to save: $e';
    notifyListeners();
    return false;
  }
}
```

---

### **Bug #3: No Save Verification in Add/Update/Delete Operations**
**Severity:** HIGH  
**Location:** `lib/providers/vault_provider.dart` - Lines 321-343

#### Problem:
When users add/update/delete entries, the app shows success toast **immediately** without waiting for Drive save confirmation.

#### Current Flow:
```dart
Future<void> addEntry(VaultEntry entry, [String? password]) async {
  _vaultData?.entries.add(entry);
  notifyListeners();  // ✅ UI updates immediately
  await _saveToDrive(password ?? _sessionPassword);  // ❌ No check if this succeeded
}
```

In `add_entry_screen.dart`:
```dart
await provider.addEntry(entry);
// ❌ Assumes save succeeded
Navigator.pop(context);
ToastNotification.show(context, 'Entry saved to vault');
```

#### Fix Required:
Return success status and verify:
```dart
// In vault_provider.dart
Future<bool> addEntry(VaultEntry entry, [String? password]) async {
  if (_vaultData == null) return false;
  
  _vaultData!.entries.add(entry);
  _vaultData = VaultData(
    vaultName: _vaultData!.vaultName,
    version: _vaultData!.version,
    lastUpdated: DateTime.now().toUtc(),
    entries: _vaultData!.entries,
  );
  notifyListeners();
  
  final success = await _saveToDrive(password ?? _sessionPassword);
  if (!success) {
    // Rollback the entry addition
    _vaultData!.entries.removeLast();
    notifyListeners();
  }
  return success;
}

// In add_entry_screen.dart
final success = await provider.addEntry(entry);
if (success && mounted) {
  Navigator.pop(context);
  ToastNotification.show(context, 'Entry saved to vault');
} else if (mounted) {
  ToastNotification.show(context, 'Failed to save entry', isError: true);
}
```

---

### **Bug #4: Vault State Not Properly Reset on Sign Out**
**Severity:** MEDIUM  
**Location:** `lib/providers/vault_provider.dart` - Line 345-355

#### Problem:
The `clear()` method resets the vault state, but there's a potential issue where:
1. User logs in with Account A
2. Creates vault
3. Logs out
4. Logs in with Account B
5. Old `_fileId` might still be cached

#### Current Code:
```dart
void clear() {
  _vaultData = null;
  _derivedKey = null;
  _sessionPassword = null;
  _salt = null;
  _iterations = null;
  _fileId = null;  // ✅ This is cleared
  _status = VaultStatus.initial;
  _driveService.reset();
  notifyListeners();
}
```

This looks correct, but we need to ensure it's called **before** the new account's vault check.

---

### **Bug #5: Potential Immutability Issue with VaultData**
**Severity:** MEDIUM  
**Location:** `lib/models/vault_entry.dart` & `lib/providers/vault_provider.dart`

#### Problem:
`VaultData` has a **mutable** `entries` list but **immutable** `lastUpdated` field. When entries are added/removed, the `VaultData` object itself is not recreated.

#### Current Structure:
```dart
class VaultData {
  final String? vaultName;
  final String version;
  final DateTime lastUpdated;  // ❌ Immutable but never updated
  final List<VaultEntry> entries;  // ✅ Mutable and modified directly
}
```

#### Issue in Provider:
```dart
Future<void> addEntry(VaultEntry entry, [String? password]) async {
  _vaultData?.entries.add(entry);  // Modifies list directly
  // lastUpdated remains unchanged!
  await _saveToDrive(password ?? _sessionPassword);
}
```

---

### **Bug #6: Missing Error Handling in DriveService**
**Severity:** HIGH  
**Location:** `lib/services/drive_service.dart`

#### Problem:
The `updateVault` method returns `false` on error but doesn't provide error details:

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
    print('Error updating vault: $e');  // ❌ Only prints, doesn't propagate
    return false;
  }
}
```

#### Issues:
- Network errors are silently swallowed
- No distinction between "no internet" vs "file not found" vs "permission denied"
- Caller can't provide meaningful error messages to user

---

## 🔧 RECOMMENDED FIXES

### Priority 1 (Immediate):
1. ✅ Update `lastUpdated` timestamp in all entry modification methods
2. ✅ Add error handling and return status from `_saveToDrive`
3. ✅ Verify save success before showing success toast

### Priority 2 (Important):
4. ✅ Add retry mechanism for failed Drive operations
5. ✅ Implement proper error propagation from DriveService
6. ✅ Add offline queue for pending changes

### Priority 3 (Enhancement):
7. ✅ Add conflict resolution for concurrent edits
8. ✅ Implement optimistic locking with version numbers
9. ✅ Add data integrity verification (checksums)

---

## 🧪 TESTING RECOMMENDATIONS

### Test Case 1: Network Interruption
1. Add 5 entries
2. Turn off internet
3. Add 5 more entries
4. Observe if app shows error or false success
5. Turn on internet and re-login
6. Verify all 10 entries are present

### Test Case 2: Rapid Entry Addition
1. Add 20 entries rapidly (within 30 seconds)
2. Log out immediately
3. Log back in
4. Verify all 20 entries are present

### Test Case 3: Account Switching
1. Login with Account A, create vault with 10 entries
2. Sign out
3. Login with Account B
4. Verify it shows "Create New Vault" (not Account A's vault)
5. Create new vault with 5 entries
6. Sign out and login with Account A again
7. Verify Account A's 10 entries are still there

---

## 📊 ROOT CAUSE ANALYSIS

The primary issue causing **data loss** is:

1. **Missing `lastUpdated` timestamp updates** → Google Drive doesn't recognize changes
2. **No save verification** → App shows success even when save fails
3. **Silent error swallowing** → Network/Drive errors are not communicated to user
4. **No retry mechanism** → Temporary network issues cause permanent data loss

The **"Create New Vault" issue** is likely caused by:
1. **Vault check timing** → Race condition between auth initialization and vault check
2. **Cached file ID issues** → Old file ID from previous session
3. **Drive API initialization** → API client not ready when vault check happens

---

## 🎯 IMPLEMENTATION PLAN

See the attached `BUG_FIX_IMPLEMENTATION.md` for detailed code changes.
