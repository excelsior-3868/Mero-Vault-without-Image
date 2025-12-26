# Phase 4: Image Attachments - Implementation Plan

**Date:** 2025-12-26  
**Status:** 🚧 IN PROGRESS  
**Complexity:** HIGH

---

## 🎯 Overview

Add ability to attach images to vault entries with encryption and Google Drive storage.

---

## ✅ Step 1: Dependencies & Model (COMPLETED)

### Dependencies Added:
- ✅ `image_picker: ^1.0.7` - Pick images from gallery/camera
- ✅ `image: ^4.1.7` - Image compression and manipulation

### Model Updates:
- ✅ Added `imageData` field to `VaultEntry`
- ✅ Updated `create()` factory method
- ✅ Updated `fromJson()` to parse image data
- ✅ Updated `toJson()` to serialize image data

**Data Structure:**
```dart
class VaultEntry {
  final String id;
  String title;
  List<VaultField> fields;
  List<String> imageData; // Base64-encoded encrypted images
  final DateTime createdAt;
  DateTime updatedAt;
}
```

---

## 📋 Step 2: Image Encryption Service (TODO)

### Create Helper Methods:

**File:** `lib/services/encryption_service.dart`

**Methods to Add:**
```dart
// Encrypt image bytes
Uint8List encryptImage(Uint8List imageBytes, Uint8List key);

// Decrypt image bytes
Uint8List decryptImage(Uint8List encryptedBytes, Uint8List key);
```

**Implementation:**
- Use AES-256-GCM (same as vault data)
- Return encrypted bytes
- Handle errors gracefully

---

## 📋 Step 3: Image Compression (TODO)

### Create Image Helper:

**File:** `lib/utils/image_helper.dart` (NEW)

**Methods:**
```dart
// Compress image to max 500KB
Future<Uint8List> compressImage(Uint8List imageBytes);

// Convert to base64
String imageToBase64(Uint8List bytes);

// Convert from base64
Uint8List base64ToImage(String base64);
```

**Compression Strategy:**
- Target: Max 500KB per image
- Quality: 85%
- Format: JPEG
- Resize if needed (max 1920x1920)

---

## 📋 Step 4: Update Add Entry Screen (TODO)

### UI Changes:

**Add Image Picker Section:**
```
┌─────────────────────────────────┐
│ Title: Gmail Account            │
├─────────────────────────────────┤
│ Fields:                         │
│ • Email                         │
│ • Password                      │
├─────────────────────────────────┤
│ Attachments (2)                 │
│ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │ IMG │ │ IMG │ │  +  │        │
│ └─────┘ └─────┘ └─────┘        │
└─────────────────────────────────┘
```

**Features:**
- Image picker button
- Thumbnail preview
- Delete image option
- Max 5 images per entry
- Show image count

---

## 📋 Step 5: Update Entry Detail Screen (TODO)

### Display Images:

**Layout:**
```
┌─────────────────────────────────┐
│ Gmail Account                   │
├─────────────────────────────────┤
│ Email: user@gmail.com           │
│ Password: ••••••••              │
├─────────────────────────────────┤
│ Attachments (2)                 │
│ ┌───────────┐ ┌───────────┐    │
│ │           │ │           │    │
│ │   Image   │ │   Image   │    │
│ │           │ │           │    │
│ └───────────┘ └───────────┘    │
└─────────────────────────────────┘
```

**Features:**
- Decrypt and display images
- Tap to view full screen
- Pinch to zoom
- Share image option

---

## 📋 Step 6: Storage Warning Enhancement (TODO)

### Update Storage Check:

**Consider Image Size:**
- Calculate total image size
- Warn if images > available storage
- Suggest compression if too large

**Warning Thresholds:**
- Low: < 10MB + image size
- Critical: < 1MB + image size

---

## 🔐 Security Considerations

### Encryption:
- ✅ Images encrypted before storage
- ✅ Same key as vault data
- ✅ Base64 encoding for JSON storage

### Storage:
- Images stored in vault JSON (encrypted)
- No separate files on Google Drive
- Included in vault backup

### Performance:
- Compress images before encryption
- Lazy load images in list view
- Cache decrypted images in memory

---

## 📊 Technical Details

### Image Flow:

**Adding Image:**
```
1. User picks image
2. Compress image (max 500KB)
3. Encrypt image bytes
4. Convert to base64
5. Add to entry.imageData[]
6. Save to vault
```

**Displaying Image:**
```
1. Get base64 from entry.imageData[]
2. Convert to bytes
3. Decrypt bytes
4. Display image
```

### Data Format:

**In Vault JSON:**
```json
{
  "entries": [
    {
      "id": "uuid",
      "title": "Gmail",
      "fields": [...],
      "image_data": [
        "base64_encrypted_image_1",
        "base64_encrypted_image_2"
      ]
    }
  ]
}
```

---

## ⚠️ Limitations

### Size Limits:
- Max 5 images per entry
- Max 500KB per image (after compression)
- Max 2.5MB total per entry

### Format Support:
- JPEG ✅
- PNG ✅ (converted to JPEG)
- GIF ❌ (not supported)
- Video ❌ (not supported)

---

## 🧪 Testing Plan

### Test Cases:

1. **Add Single Image**
   - Pick from gallery
   - Verify compression
   - Verify encryption
   - Verify save

2. **Add Multiple Images**
   - Add 5 images
   - Verify all saved
   - Verify size limits

3. **Display Images**
   - View entry with images
   - Verify decryption
   - Verify display quality

4. **Delete Images**
   - Remove image from entry
   - Verify deletion
   - Verify save

5. **Storage Warning**
   - Add large images
   - Verify warning appears
   - Verify size calculation

6. **Export with Images**
   - Export vault
   - Verify images included
   - Verify decryption

---

## 📝 Implementation Checklist

### Phase 4A: Core Functionality
- [x] Add dependencies
- [x] Update VaultEntry model
- [ ] Add image encryption methods
- [ ] Add image compression helper
- [ ] Update Add Entry screen UI
- [ ] Implement image picker
- [ ] Implement image save logic

### Phase 4B: Display & Edit
- [ ] Update Entry Detail screen
- [ ] Display encrypted images
- [ ] Full-screen image viewer
- [ ] Edit images in entry
- [ ] Delete images

### Phase 4C: Polish
- [ ] Update storage warnings
- [ ] Add loading states
- [ ] Error handling
- [ ] Image compression optimization
- [ ] Memory management

---

## 🚀 Next Steps

**Immediate:**
1. Create image encryption methods
2. Create image compression helper
3. Update Add Entry screen UI

**Then:**
1. Implement image picker
2. Test encryption/decryption
3. Update Entry Detail screen

**Finally:**
1. Polish UI/UX
2. Optimize performance
3. Comprehensive testing

---

## 💡 Future Enhancements

**Possible Additions:**
- Image annotations
- OCR text extraction
- Image search
- Thumbnail generation
- Cloud-only storage option
- Video support
- PDF support

---

**Status:** Model updated, ready for implementation  
**Next:** Image encryption & compression helpers  
**ETA:** 2-3 hours for full implementation
