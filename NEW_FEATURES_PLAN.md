# New Features Implementation Plan

**Date:** 2025-12-26  
**Status:** 🚧 IN PROGRESS

---

## 📋 Features to Implement

### ✅ Feature 1: Google Drive Storage Status in Profile
**Complexity:** Medium  
**Files to Modify:**
- `lib/services/drive_service.dart` - Add method to get storage quota
- `lib/features/profile/profile_screen.dart` - Display storage info

**Implementation:**
- Add `getStorageQuota()` method to DriveService
- Display used/total storage with progress bar
- Show percentage and formatted sizes (GB/MB)

---

### ✅ Feature 2: Download Vault (Decrypted)
**Complexity:** Medium  
**Files to Modify:**
- `lib/features/profile/profile_screen.dart` - Add download button
- `lib/providers/vault_provider.dart` - Add export method

**Implementation:**
- Add "Export Vault" button in profile
- Require biometric/password authentication
- Export as readable JSON file
- Use file_picker/path_provider for save location

---

### ✅ Feature 3: Remove Developer Details
**Complexity:** Easy  
**Files to Modify:**
- `lib/features/profile/profile_screen.dart` - Remove developer section

**Implementation:**
- Remove developer name/contact section
- Keep only app version and essential info

---

### ✅ Feature 4: About App Section
**Complexity:** Easy  
**Files to Create:**
- `lib/features/profile/about_app_screen.dart` - New screen

**Implementation:**
- Create dedicated "About" screen
- Include:
  - App description
  - Key features list
  - Security information
  - Important reminders
  - Privacy policy
  - Terms of use

---

### ✅ Feature 5: Dashboard Grid Layout (2 Cards per Row)
**Complexity:** Easy  
**Files to Modify:**
- `lib/features/home/dashboard_screen.dart` - Change ListView to GridView

**Implementation:**
- Replace ListView with GridView.builder
- Set crossAxisCount: 2
- Adjust card design for grid layout
- Maintain responsive design

---

### ✅ Feature 6: Image Attachments for Entries
**Complexity:** High  
**Files to Modify:**
- `lib/models/vault_entry.dart` - Add image field
- `lib/features/home/add_entry_screen.dart` - Add image picker
- `lib/features/home/entry_detail_screen.dart` - Display images
- `lib/services/drive_service.dart` - Upload/download encrypted images
- `lib/providers/vault_provider.dart` - Handle image encryption

**Implementation:**
- Add image_picker dependency
- Store images as base64 in encrypted form
- Upload to Google Drive in separate folder
- Display images in entry detail view
- Add image compression to save space

---

### ✅ Feature 7: Storage Warning
**Complexity:** Medium  
**Files to Modify:**
- `lib/providers/vault_provider.dart` - Check storage before save
- `lib/features/home/add_entry_screen.dart` - Show warning

**Implementation:**
- Check available storage before adding entry
- Show warning if < 10MB available
- Prevent save if storage full
- Suggest cleanup options

---

## 📦 New Dependencies Required

```yaml
# Add to pubspec.yaml
dependencies:
  image_picker: ^1.0.7
  path_provider: ^2.1.2
  file_picker: ^6.1.1
  image: ^4.1.7  # For image compression
```

---

## 🗂️ Implementation Order

1. ✅ **Phase 1: Simple Updates** (30 min)
   - Feature 3: Remove developer details
   - Feature 5: Grid layout for dashboard
   - Feature 4: About app screen

2. ✅ **Phase 2: Drive Integration** (45 min)
   - Feature 1: Storage status
   - Feature 7: Storage warnings

3. ✅ **Phase 3: Export Feature** (30 min)
   - Feature 2: Download vault

4. ✅ **Phase 4: Image Support** (90 min)
   - Feature 6: Image attachments

---

## 📝 Detailed Implementation Steps

### Phase 1: Simple Updates

#### Step 1.1: Remove Developer Details
```dart
// In profile_screen.dart
// Remove section with developer name/email
```

#### Step 1.2: Grid Layout
```dart
// In dashboard_screen.dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.85,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemCount: entries.length,
  itemBuilder: (context, index) => EntryCard(...),
)
```

#### Step 1.3: About App Screen
```dart
// Create new file: about_app_screen.dart
// Include:
// - App name and version
// - Feature list
// - Security info
// - Important notes
```

---

### Phase 2: Drive Integration

#### Step 2.1: Storage Quota API
```dart
// In drive_service.dart
Future<StorageQuota?> getStorageQuota() async {
  final api = await _api;
  final about = await api.about.get($fields: 'storageQuota');
  return StorageQuota(
    limit: about.storageQuota?.limit,
    usage: about.storageQuota?.usage,
  );
}
```

#### Step 2.2: Display Storage
```dart
// In profile_screen.dart
FutureBuilder<StorageQuota>(
  future: driveService.getStorageQuota(),
  builder: (context, snapshot) {
    // Show progress bar and stats
  },
)
```

#### Step 2.3: Storage Warning
```dart
// In vault_provider.dart
Future<bool> _checkStorageAvailable() async {
  final quota = await _driveService.getStorageQuota();
  final available = quota.limit - quota.usage;
  return available > 10 * 1024 * 1024; // 10MB minimum
}
```

---

### Phase 3: Export Feature

#### Step 3.1: Export Method
```dart
// In vault_provider.dart
Future<String> exportVaultAsJson() async {
  if (_vaultData == null) throw Exception('No vault loaded');
  
  final exportData = {
    'vault_name': _vaultData!.vaultName,
    'exported_at': DateTime.now().toIso8601String(),
    'entries': _vaultData!.entries.map((e) => e.toJson()).toList(),
  };
  
  return JsonEncoder.withIndent('  ').convert(exportData);
}
```

#### Step 3.2: Save to File
```dart
// In profile_screen.dart
final json = await vaultProvider.exportVaultAsJson();
final directory = await getApplicationDocumentsDirectory();
final file = File('${directory.path}/vault_export.json');
await file.writeAsString(json);
```

---

### Phase 4: Image Support

#### Step 4.1: Update Model
```dart
// In vault_entry.dart
class VaultEntry {
  final String id;
  final String title;
  final List<VaultField> fields;
  final List<String>? imageIds; // New field
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### Step 4.2: Image Picker
```dart
// In add_entry_screen.dart
final ImagePicker _picker = ImagePicker();

Future<void> _pickImage() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    // Compress and encrypt
    final bytes = await image.readAsBytes();
    final compressed = await _compressImage(bytes);
    final encrypted = _encryptImage(compressed);
    // Upload to Drive
    final imageId = await _uploadImage(encrypted);
    setState(() => _imageIds.add(imageId));
  }
}
```

#### Step 4.3: Image Storage
```dart
// In drive_service.dart
Future<String?> uploadImage(Uint8List encryptedData, String entryId) async {
  final fileName = 'img_${entryId}_${DateTime.now().millisecondsSinceEpoch}.enc';
  // Upload to appDataFolder/images/
}

Future<Uint8List?> downloadImage(String imageId) async {
  // Download and return encrypted bytes
}
```

---

## 🎨 UI/UX Considerations

### Storage Display
```
┌─────────────────────────────────┐
│ Google Drive Storage            │
├─────────────────────────────────┤
│ ████████████░░░░░░░░ 65%       │
│ 9.75 GB of 15 GB used          │
│ 5.25 GB available              │
└─────────────────────────────────┘
```

### Grid Layout
```
┌──────────┬──────────┐
│  Card 1  │  Card 2  │
├──────────┼──────────┤
│  Card 3  │  Card 4  │
└──────────┴──────────┘
```

### Image in Entry
```
┌─────────────────────────────────┐
│ Entry Title                     │
├─────────────────────────────────┤
│ Username: john@example.com      │
│ Password: ••••••••              │
│                                 │
│ Attachments: (2)                │
│ ┌─────┐ ┌─────┐                │
│ │ IMG │ │ IMG │                │
│ └─────┘ └─────┘                │
└─────────────────────────────────┘
```

---

## ⚠️ Important Notes

1. **Image Size Limits**: Compress images to max 500KB each
2. **Storage Check**: Always check before upload
3. **Encryption**: All images encrypted before upload
4. **Cleanup**: Delete images when entry is deleted
5. **Performance**: Lazy load images in list view

---

## 🧪 Testing Checklist

- [ ] Storage quota displays correctly
- [ ] Export creates valid JSON file
- [ ] Grid layout responsive on different screens
- [ ] Images upload and display correctly
- [ ] Storage warning appears when needed
- [ ] About screen shows all information
- [ ] Developer details removed

---

**Plan Created:** 2025-12-26  
**Estimated Time:** 3-4 hours  
**Ready to Implement:** ✅ YES
