# Mero Vault: Complete Code Documentation

## Table of Contents
1. [Services Layer](#services-layer)
2. [Providers Layer](#providers-layer)
3. [Features/Screens](#featuresscreens)
4. [Models](#models)
5. [Utilities](#utilities)
6. [Widgets](#widgets)

---

## Services Layer

### 1. AuthService (`lib/services/auth_service.dart`)
**Purpose**: Manages Google Sign-In authentication and session persistence.

**Key Features**:
- Google OAuth integration
- Persistent login state using `SharedPreferences`
- Silent sign-in on app restart
- Logout with complete session cleanup

**Main Methods**:
```dart
Future<void> signIn()              // Initiates Google Sign-In
Future<void> signOut()             // Signs out and clears session
GoogleSignInAccount? currentUser   // Current authenticated user
```

**How It Works**:
1. On app start, checks `SharedPreferences` for previous login
2. Attempts silent sign-in if user was previously logged in
3. Stores login state to prevent unnecessary login prompts
4. Provides authenticated HTTP client for Drive API

---

### 2. BiometricService (`lib/services/biometric_service.dart`)
**Purpose**: Handles fingerprint/FaceID authentication and secure key storage.

**Key Features**:
- Device biometric capability detection
- Secure storage using encrypted SharedPreferences (Android)
- Master key encryption and retrieval
- Biometric prompt customization

**Main Methods**:
```dart
Future<bool> authenticate()                    // Shows biometric prompt
Future<bool> enableBiometrics(String key)      // Stores encrypted key
Future<String?> getMasterKey()                 // Retrieves key after auth
Future<void> disableBiometrics()               // Clears stored credentials
```

**Security Implementation**:
- Uses `local_auth` package (v3.0.0+)
- Stores master key in `FlutterSecureStorage` with hardware encryption
- Configured with `encryptedSharedPreferences: true` for Android
- Requires biometric authentication before revealing stored key

---

### 3. DriveService (`lib/services/drive_service.dart`)
**Purpose**: Manages Google Drive API interactions for vault file storage.

**Key Features**:
- Hidden `appDataFolder` storage (invisible to user in Drive UI)
- File upload/download with retry logic
- Vault existence detection
- Error differentiation (missing file vs. connection error)

**Main Methods**:
```dart
Future<File?> getVaultFile()                   // Searches for vault.json
Future<String?> getVaultContent(String id)     // Downloads encrypted content
Future<void> uploadVaultContent(String json)   // Uploads encrypted vault
Future<void> reset()                           // Clears cached API instance
```

**File Structure**:
- Filename: `vault.json`
- Location: Google Drive `appDataFolder` (hidden from user)
- Content: Encrypted JSON blob

---

### 4. EncryptionService (`lib/services/encryption_service.dart`)
**Purpose**: Provides cryptographic operations for vault security.

**Key Features**:
- PBKDF2 key derivation (150,000 iterations)
- AES-256-GCM encryption/decryption
- Random salt generation
- IV (Initialization Vector) management

**Main Methods**:
```dart
Uint8List deriveKey(String password, Uint8List salt)  // Password → Key
String encrypt(String plainText, Uint8List key)       // Encrypt data
String decrypt(String encrypted, Uint8List key)       // Decrypt data
Uint8List generateSalt()                              // Random 16-byte salt
```

**Encryption Format**:
```
Encrypted String: "base64_iv:base64_ciphertext"
Example: "kJ8x2mP9qL4n:aGVsbG8gd29ybGQ="
```

**Security Parameters**:
- Algorithm: AES-256-GCM (Authenticated Encryption)
- Key Length: 256 bits (32 bytes)
- IV Length: 12 bytes (GCM standard)
- PBKDF2 Iterations: 150,000
- Hash Function: HMAC-SHA256

---

## Providers Layer

### VaultProvider (`lib/providers/vault_provider.dart`)
**Purpose**: Central state management for vault data and operations.

**State Variables**:
```dart
VaultStatus _status                    // Current vault state
VaultData? _vaultData                  // Decrypted vault content
Uint8List? _derivedKey                 // Session encryption key
String? _errorMessage                  // Last error for UI display
```

**VaultStatus Enum**:
- `initial`: App just started
- `checking`: Verifying vault existence
- `notFound`: No vault on Drive
- `found`: Vault exists but locked
- `unlocked`: Vault decrypted and ready
- `error`: Connection/API error

**Key Methods**:
```dart
Future<void> checkVaultExistence()              // Checks Drive for vault
Future<bool> unlock(String password)            // Unlocks with password
Future<bool> unlockWithKey(Uint8List key)       // Unlocks with biometric key
Future<void> createNewVault(String name, pwd)   // Creates new vault
Future<void> addEntry(VaultEntry entry)         // Adds encrypted entry
Future<void> updateEntry(VaultEntry entry)      // Updates entry
Future<void> deleteEntry(String id)             // Deletes entry
void clear()                                    // Locks vault (clears memory)
```

**Data Flow**:
1. User enters password → PBKDF2 derives key
2. Key decrypts vault JSON from Drive
3. JSON parsed into `VaultData` model
4. Entries displayed in UI
5. On save: Encrypt → Upload to Drive

---

## Features/Screens

### 1. Splash Screen (`lib/features/splash/splash_screen.dart`)
**Purpose**: Initial loading screen with branding.

**Features**:
- Displays app logo and name
- Automatic navigation after 2 seconds
- Smooth fade transition to next screen

---

### 2. Login Screen (`lib/features/auth/login_screen.dart`)
**Purpose**: Google Sign-In interface.

**Features**:
- Google Sign-In button
- App branding and description
- Error handling for failed authentication
- Automatic navigation on successful login

**UI Elements**:
- Hero logo animation
- "Sign in with Google" button
- Privacy/security messaging

---

### 3. Initialization Screen (`lib/features/splash/initialization_screen.dart`)
**Purpose**: Vault detection and unlock interface.

**Features**:
- Automatic vault existence check
- Biometric unlock (if enabled)
- Master password input
- Password visibility toggle
- Standalone biometric button
- "Forgot Password" → Create New Vault option
- Error display with sign-out option

**State Management**:
```dart
bool _isChecking              // Checking vault status
bool _showPasswordInput       // Show password field
bool _isVaultSyncing          // Decrypting vault
bool _isPasswordVisible       // Password visibility toggle
String _statusMessage         // Current status text
```

**Flow**:
1. Check if vault exists on Drive
2. If exists + biometrics enabled → Auto-prompt
3. If biometrics fail/disabled → Show password field
4. On unlock → Navigate to Dashboard

---

### 4. Create Vault Screen (`lib/features/auth/create_vault_screen.dart`)
**Purpose**: New vault creation interface.

**Features**:
- Vault name input
- Master password creation
- Password confirmation validation
- Password visibility toggles
- Optional biometric setup
- Automatic keyboard dismissal on submit

**Validation Rules**:
- Password minimum 8 characters
- Password and confirmation must match
- Vault name required

**Post-Creation**:
- Optionally enables biometrics
- Navigates to Dashboard
- Vault immediately synced to Drive

---

### 5. Dashboard Screen (`lib/features/home/dashboard_screen.dart`)
**Purpose**: Main vault entry list and search.

**Features**:
- Search bar with real-time filtering
- Entry cards with title and field preview
- Add Entry button in app bar
- Tap to view entry details
- Empty state messaging
- Auto-focus disabled on search

**Entry Card Display**:
- Title (bold)
- First field preview (e.g., "Username: john@example.com")
- Tap → Navigate to Entry Detail

**Search Logic**:
```dart
entries.where((e) => e.title.toLowerCase().contains(query))
```

---

### 6. Add Entry Screen (`lib/features/home/add_entry_screen.dart`)
**Purpose**: Create or edit vault entries.

**Features**:
- Title input
- Dynamic field addition/removal
- Field type selection (Username, Password, Pin Code, Transaction Password, URL, Custom)
- Password visibility toggle per field
- "Treat as Sensitive" checkbox for passwords
- Auto-obscure for password types
- Custom field label input
- Keyboard auto-dismiss on save
- Toast notifications for success/error

**Field Types**:
1. **Username**: Plain text, person icon
2. **Password**: Obscured, key icon, sensitive toggle
3. **Pin Code**: Obscured, password icon, sensitive toggle
4. **Transaction Password**: Obscured, lock-clock icon, sensitive toggle
5. **URL**: Plain text, link icon
6. **Custom**: User-defined label, info icon

**Field Controller**:
```dart
class _FieldController {
  String selectedType           // Field type
  TextEditingController label   // Custom label
  TextEditingController value   // Field value
  bool isObscured              // Requires auth to view
  bool isPasswordVisible       // Temporary visibility toggle
}
```

**Save Flow**:
1. Validate form
2. Dismiss keyboard
3. Convert fields to `VaultField` models
4. Call `VaultProvider.addEntry()` or `updateEntry()`
5. Encrypt and upload to Drive
6. Show toast notification
7. Navigate back to Dashboard

---

### 7. Entry Detail Screen (`lib/features/home/entry_detail_screen.dart`)
**Purpose**: View and manage individual vault entries.

**Features**:
- Entry title with edit/delete buttons
- Field display with icons
- Password obscuration (dots)
- Biometric reveal for sensitive fields
- Copy to clipboard
- Last updated timestamp
- Add New Entry button in app bar

**Field Display Logic**:
```dart
if (field.isObscured && (isPassword || isPin || isTransaction)) {
  display: "••••••••••••"
  show: Eye icon (requires auth)
} else {
  display: field.value
}
```

**Actions**:
- **Edit**: Opens Add Entry screen in edit mode
- **Delete**: Confirmation dialog → Remove from vault
- **Reveal**: Biometric/password auth → Show plain text
- **Copy**: Clipboard copy with confirmation

---

### 8. Profile Screen (`lib/features/profile/profile_screen.dart`)
**Purpose**: User settings and vault management.

**Features**:
- User profile display (Google account)
- Vault name display
- Biometric toggle with authentication
- Reset & Create New Vault (with secondary auth)
- Logout with confirmation
- App version and developer info

**Biometric Toggle**:
- ON: Stores master key in secure storage
- OFF: Deletes stored credentials
- Requires vault to be unlocked

**Reset Vault Flow**:
1. Show warning dialog
2. Require biometric OR master password
3. If authenticated → Navigate to Create Vault
4. Old vault overwritten on Drive

**Logout Flow**:
1. Disable biometrics
2. Clear vault from memory
3. Sign out of Google
4. Navigate to Login screen

---

## Models

### VaultEntry (`lib/models/vault_entry.dart`)
```dart
class VaultEntry {
  String id                    // Unique identifier
  String title                 // Entry name
  List<VaultField> fields      // Entry fields
  DateTime createdAt           // Creation timestamp
  DateTime updatedAt           // Last modified timestamp
}
```

### VaultField (`lib/models/vault_entry.dart`)
```dart
class VaultField {
  String label                 // Field name (e.g., "Password")
  String value                 // Field content
  bool isObscured             // Requires auth to view
}
```

### VaultData (`lib/models/vault_entry.dart`)
```dart
class VaultData {
  String vaultName            // User-defined vault name
  String version              // Vault format version
  DateTime lastUpdated        // Last sync timestamp
  List<VaultEntry> entries    // All vault entries
}
```

---

## Utilities

### SecurityUtils (`lib/utils/security_utils.dart`)
**Purpose**: Reusable authentication helpers.

**Main Method**:
```dart
static Future<bool> authenticate(BuildContext context)
```

**Flow**:
1. Check if biometrics enabled
2. If yes → Prompt biometric
3. If no/fail → Show password dialog
4. Verify password against current vault
5. Return authentication result

---

### Transitions (`lib/utils/transitions.dart`)
**Purpose**: Custom page route animations.

**Available Transitions**:
1. **FadePageRoute**: Simple fade (200ms)
2. **SlideUpPageRoute**: Slide + fade (250ms, easeOutQuart)

**Usage**:
```dart
Navigator.push(context, SlideUpPageRoute(child: AddEntryScreen()));
```

---

## Widgets

### BrandedAppBar (`lib/widgets/branded_app_bar.dart`)
**Purpose**: Consistent app bar across all screens.

**Features**:
- Logo display (optional)
- Title text
- Custom actions support
- Red theme color

**Usage**:
```dart
BrandedAppBar(
  title: 'MERO VAULT',
  showLogo: true,
  actions: [IconButton(...)],
)
```

---

### ToastNotification (`lib/widgets/toast_notification.dart`)
**Purpose**: Professional centered toast messages.

**Features**:
- Centered overlay
- Fade + scale animation
- Auto-dismiss after 3 seconds
- Success/error variants
- Icon support

**Usage**:
```dart
ToastNotification.show(
  context,
  'Entry saved successfully',
  isError: false,
);
```

**Design**:
- Success: Dark gray background, checkmark icon
- Error: Red background, error icon
- Rounded corners, shadow, white text

---

## Data Encryption Flow

### Creating a Vault
```
1. User enters password: "MySecurePass123"
2. Generate random salt: [16 random bytes]
3. PBKDF2(password, salt, 150000) → 32-byte key
4. Create vault JSON:
   {
     "version": "1.0",
     "salt": "base64_salt",
     "iterations": 150000,
     "vault": {
       "vault_name": "My Vault",
       "entries": []
     }
   }
5. Encrypt vault section with AES-GCM
6. Upload to Google Drive appDataFolder
```

### Unlocking a Vault
```
1. Download vault.json from Drive
2. Extract salt and iterations
3. User enters password
4. PBKDF2(password, salt, iterations) → derived key
5. Attempt to decrypt vault section
6. If successful → Parse JSON → Load entries
7. If failed → "Incorrect Password"
```

### Adding an Entry
```
1. User fills form (title, fields)
2. Create VaultEntry object
3. Add to entries list in memory
4. Serialize entire vault to JSON
5. Encrypt JSON with session key
6. Upload to Drive (overwrites old file)
```

---

## Security Best Practices Implemented

1. **Zero-Knowledge**: Master password never stored or transmitted
2. **Memory Safety**: Vault cleared on app background/close
3. **Authenticated Encryption**: AES-GCM prevents tampering
4. **Key Derivation**: PBKDF2 with 150k iterations resists brute-force
5. **Biometric Storage**: Hardware-encrypted secure storage
6. **Session Keys**: Derived key only in RAM during active session
7. **Secondary Auth**: Critical actions require re-authentication
8. **Auto-Lock**: Vault locks when app is backgrounded

---

## File Structure Summary

```
lib/
├── features/
│   ├── auth/
│   │   ├── login_screen.dart              (Google Sign-In)
│   │   └── create_vault_screen.dart       (New vault creation)
│   ├── home/
│   │   ├── dashboard_screen.dart          (Entry list)
│   │   ├── add_entry_screen.dart          (Create/edit entries)
│   │   └── entry_detail_screen.dart       (View entry)
│   ├── navigation/
│   │   └── nav_bar_wrapper.dart           (Bottom navigation)
│   ├── profile/
│   │   └── profile_screen.dart            (Settings)
│   └── splash/
│       ├── splash_screen.dart             (Initial loading)
│       └── initialization_screen.dart     (Vault unlock)
├── models/
│   └── vault_entry.dart                   (Data models)
├── providers/
│   └── vault_provider.dart                (State management)
├── services/
│   ├── auth_service.dart                  (Google auth)
│   ├── biometric_service.dart             (Fingerprint/Face)
│   ├── drive_service.dart                 (Cloud storage)
│   └── encryption_service.dart            (Crypto)
├── utils/
│   ├── security_utils.dart                (Auth helpers)
│   └── transitions.dart                   (Page animations)
├── widgets/
│   ├── branded_app_bar.dart               (Custom app bar)
│   └── toast_notification.dart            (Toast messages)
└── main.dart                              (App entry point)
```

---

**Last Updated**: 2025-12-25  
**Total Lines of Code**: ~5,500  
**Dart Version**: 3.x  
**Flutter Version**: 3.x
