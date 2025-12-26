# Testing Guide - All New Features

**Date:** 2025-12-26  
**App Version:** 2.0  
**Status:** ✅ READY FOR TESTING

---

## 🧪 Testing Checklist

### Phase 1: UI Improvements

#### ✅ Test 1: Dashboard Grid Layout (3 Cards per Row)
**Location:** Dashboard Screen

**Steps:**
1. Open the app
2. Login to your vault
3. Navigate to Dashboard

**Expected Results:**
- [ ] Entries displayed in 3 columns
- [ ] Cards are evenly spaced
- [ ] Icons are 40x40 pixels
- [ ] Text is readable (12px title, 10px subtitle)
- [ ] Tap on card opens entry details
- [ ] Long press shows edit/delete menu

**Visual Check:**
```
┌────────┬────────┬────────┐
│ Card 1 │ Card 2 │ Card 3 │
├────────┼────────┼────────┤
│ Card 4 │ Card 5 │ Card 6 │
└────────┴────────┴────────┘
```

---

#### ✅ Test 2: About App Screen
**Location:** Profile → About Mero Vault

**Steps:**
1. Go to Profile screen
2. Scroll to ABOUT section
3. Tap "About Mero Vault"

**Expected Results:**
- [ ] About screen opens
- [ ] Logo displays without white background
- [ ] App name and version shown
- [ ] All sections visible:
  - [ ] Description
  - [ ] Key Features (6 items)
  - [ ] Security (4 items)
  - [ ] Important Reminders (3 warning cards)
  - [ ] Privacy (4 items)
- [ ] Scrolling works smoothly
- [ ] Back button returns to profile

---

#### ✅ Test 3: Developer Details Removed
**Location:** Profile → About Section

**Expected Results:**
- [ ] No "Developer: Subin Bajracharya" shown
- [ ] Only "About Mero Vault" and "App Version" visible

---

### Phase 2: Google Drive Integration

#### ✅ Test 4: Storage Status Display
**Location:** Profile → Google Drive Storage (below Security)

**Steps:**
1. Go to Profile screen
2. Scroll to "GOOGLE DRIVE STORAGE" section
3. Wait for loading to complete

**Expected Results:**
- [ ] Loading indicator shows initially
- [ ] Storage card displays with:
  - [ ] Cloud icon (blue)
  - [ ] "Storage Usage" title
  - [ ] Used/Total size (e.g., "9.75 GB of 15 GB used")
  - [ ] Percentage (e.g., "65.3%")
  - [ ] Progress bar
  - [ ] Available space (e.g., "5.25 GB available")
- [ ] Progress bar color:
  - [ ] Green if > 10MB available
  - [ ] Orange if < 10MB available
  - [ ] Red if < 1MB available
- [ ] Warning badge shows if storage is low

**Error Case:**
- [ ] If API fails, shows "Unable to fetch storage info"

---

#### ✅ Test 5: Storage Warnings Before Save
**Location:** Add Entry Screen

**Test 5a: Normal Storage (> 10MB)**
**Steps:**
1. Tap "Add New Entry"
2. Fill in entry details
3. Tap Save

**Expected Results:**
- [ ] Entry saves normally
- [ ] No warnings shown
- [ ] Success toast appears

**Test 5b: Low Storage (< 10MB, > 1MB)**
**Steps:**
1. (Simulate low storage or wait until < 10MB)
2. Add new entry
3. Tap Save

**Expected Results:**
- [ ] Orange toast warning: "Warning: Low storage space on Google Drive"
- [ ] Entry still saves
- [ ] Success toast appears

**Test 5c: Critical Storage (< 1MB)**
**Steps:**
1. (Simulate critical storage or wait until < 1MB)
2. Add new entry
3. Tap Save

**Expected Results:**
- [ ] Red dialog appears: "Critical Storage"
- [ ] Message: "Your Google Drive storage is almost full..."
- [ ] Two buttons: "Cancel" and "Proceed Anyway"
- [ ] If Cancel: Entry not saved, returns to form
- [ ] If Proceed: Entry saves, success toast appears

---

### Phase 3: Export Feature

#### ✅ Test 6: Export Vault
**Location:** Profile → Security → Export Vault

**Test 6a: Export with Biometric (if enabled)**
**Steps:**
1. Go to Profile
2. Tap "Export Vault"
3. Authenticate with fingerprint/face ID

**Expected Results:**
- [ ] Biometric prompt appears
- [ ] After successful auth, toast: "Exporting vault..."
- [ ] Native share dialog appears
- [ ] File name: `mero_vault_export_YYYY-MM-DDTHH-MM-SS.json`
- [ ] Can choose save location
- [ ] After saving, toast: "Vault exported successfully!"

**Test 6b: Export with Master Password**
**Steps:**
1. Disable biometric or let it fail
2. Tap "Export Vault"
3. Enter master password in dialog

**Expected Results:**
- [ ] Password dialog appears
- [ ] Title: "Verify Master Password"
- [ ] Message: "Enter your master password to export vault data."
- [ ] Password field (obscured)
- [ ] Cancel and Verify buttons
- [ ] After correct password, export proceeds
- [ ] After wrong password, error toast appears

**Test 6c: Export Cancelled**
**Steps:**
1. Tap "Export Vault"
2. Tap Cancel on auth dialog

**Expected Results:**
- [ ] Toast: "Authentication failed. Export cancelled."
- [ ] No file created
- [ ] Returns to profile

**Test 6d: Verify Exported File**
**Steps:**
1. Successfully export vault
2. Open exported JSON file in text editor

**Expected Results:**
- [ ] File is valid JSON
- [ ] Contains all entries
- [ ] Passwords are in plain text (decrypted)
- [ ] Proper formatting with indentation
- [ ] Includes metadata:
  - [ ] vault_name
  - [ ] version
  - [ ] exported_at
  - [ ] last_updated
  - [ ] total_entries

**Example JSON Structure:**
```json
{
  "vault_name": "My Vault",
  "version": "1.0",
  "exported_at": "2025-12-26T16:00:00.000Z",
  "total_entries": 5,
  "entries": [...]
}
```

---

## 🎨 Visual Testing

### Color Scheme Verification:
- [ ] Primary Red: `#D32F2F`
- [ ] Primary Blue: `#0066CC`
- [ ] Success Green: `#4CAF50`
- [ ] Warning Orange: Orange shade
- [ ] Error Red: Red shade
- [ ] Background: `#F8F9FB`

### Typography:
- [ ] Titles are bold and readable
- [ ] Subtitles are gray and smaller
- [ ] Consistent font sizes across app

### Spacing:
- [ ] Consistent padding (16px, 12px, 8px)
- [ ] Proper spacing between sections (32px)
- [ ] Cards have proper margins

---

## 🔄 Integration Testing

### Test 7: Complete User Flow
**Steps:**
1. Login to app
2. View dashboard (3-column grid)
3. Add new entry (check storage warning)
4. View entry details
5. Go to Profile
6. Check storage status
7. Export vault
8. View About screen
9. Logout

**Expected Results:**
- [ ] All screens work smoothly
- [ ] No crashes or errors
- [ ] Transitions are smooth
- [ ] Data persists correctly

---

## 📱 Platform Testing

### Android:
- [ ] All features work
- [ ] Share dialog is native
- [ ] Biometric works (fingerprint)
- [ ] File save works

### iOS (if applicable):
- [ ] All features work
- [ ] Share dialog is native
- [ ] Biometric works (Face ID/Touch ID)
- [ ] File save works

### Windows (if applicable):
- [ ] All features work
- [ ] File save works
- [ ] UI scales properly

---

## ⚠️ Error Scenarios

### Test 8: Network Errors
**Steps:**
1. Turn off internet
2. Try to check storage
3. Try to save entry
4. Try to export vault

**Expected Results:**
- [ ] Storage shows error message
- [ ] Save fails with appropriate error
- [ ] Export may fail or succeed (depends on cached data)
- [ ] User-friendly error messages

### Test 9: Authentication Failures
**Steps:**
1. Try to export with wrong password
2. Cancel biometric prompt
3. Fail biometric 3 times

**Expected Results:**
- [ ] Appropriate error messages
- [ ] No crashes
- [ ] Can retry authentication

---

## 🐛 Bug Reporting Template

If you find any issues, report using this format:

```
**Feature:** [Which feature]
**Platform:** [Android/iOS/Windows]
**Steps to Reproduce:**
1. 
2. 
3. 

**Expected:** [What should happen]
**Actual:** [What actually happened]
**Screenshot:** [If applicable]
```

---

## ✅ Sign-Off Checklist

After testing all features:

- [ ] All Phase 1 features work correctly
- [ ] All Phase 2 features work correctly
- [ ] All Phase 3 features work correctly
- [ ] No critical bugs found
- [ ] UI looks professional
- [ ] Performance is acceptable
- [ ] Ready for production

---

## 📊 Test Results Summary

**Date Tested:** ___________  
**Tester:** ___________  
**Platform:** ___________  

**Results:**
- Tests Passed: ___ / ___
- Tests Failed: ___ / ___
- Bugs Found: ___

**Overall Status:** ⬜ PASS / ⬜ FAIL

**Notes:**
_________________________________
_________________________________
_________________________________

---

**Happy Testing!** 🧪✨
