# Master Password Behavior - Important Information

## Understanding Master Password Persistence

### How It Works

When you create a vault with a master password, here's what happens:

1. **Password → Encryption Key**
   - Your master password is converted into a cryptographic key using PBKDF2
   - A random "salt" is generated and stored with your vault
   - The salt + password combination creates a unique encryption key

2. **Vault Storage**
   - Your vault data is encrypted with this key
   - The encrypted vault is uploaded to Google Drive
   - **The master password itself is NEVER stored anywhere**

3. **Unlocking the Vault**
   - When you enter your password, the app:
     - Downloads the vault from Google Drive
     - Extracts the salt
     - Derives the key from your password + salt
     - Attempts to decrypt the vault
     - If decryption succeeds → Correct password
     - If decryption fails → Incorrect password

### After Uninstalling and Reinstalling

**This is the expected and correct behavior:**

✅ **Your vault data is safe on Google Drive**
- The encrypted vault file remains on your Google Drive
- It's stored in a hidden folder (`appDataFolder`)
- You won't see it in your normal Drive interface

✅ **You must use the SAME master password**
- The password you originally created the vault with
- This is the ONLY way to decrypt your data
- There is no password recovery option (by design for security)

❌ **What gets deleted when you uninstall:**
- Local biometric credentials
- App cache and temporary data
- Session keys in memory

### Troubleshooting "Incorrect Password"

If you're certain you're using the correct password but it's not working:

1. **Check for typos**
   - Use the eye icon to verify what you're typing
   - Watch for autocorrect on mobile keyboards
   - Check for accidental spaces (the app now trims them automatically)

2. **Verify you're using the original password**
   - Not a password you changed later
   - Not a password from a different vault
   - The exact password from when you first created the vault

3. **Check your Google account**
   - Make sure you're signed into the SAME Google account
   - The vault is tied to your Google account
   - Different account = different vault

### Security Design

This behavior is **intentional** for maximum security:

- **Zero-Knowledge Architecture**: We never store your master password
- **No Password Recovery**: If you forget your password, the data cannot be recovered
- **No Backdoor**: Not even the developer can access your vault
- **True Privacy**: Only you can decrypt your data

### Best Practices

1. **Remember Your Master Password**
   - Write it down and store it securely (physical location)
   - Use a password you won't forget
   - Don't use a password you use elsewhere

2. **Test After Creation**
   - After creating a vault, immediately test unlocking it
   - Add a test entry and verify you can access it
   - This confirms your password is working

3. **Biometric Backup**
   - Enable biometrics for convenience
   - But remember: biometrics are device-specific
   - You still need the master password for new devices

### What to Do If You Forgot Your Password

Unfortunately, if you've truly forgotten your master password:

1. **There is no recovery option** (by design)
2. **Your data cannot be decrypted** (mathematically impossible without the key)
3. **You must create a new vault** (which will overwrite the old one)

This is the trade-off for true zero-knowledge security. Your data is completely private, but you are solely responsible for remembering your password.

---

## Technical Details

### Encryption Process
```
Master Password: "MySecurePass123"
        ↓
Random Salt: [16 bytes]
        ↓
PBKDF2 (150,000 iterations)
        ↓
256-bit Encryption Key
        ↓
AES-256-GCM Encryption
        ↓
Encrypted Vault → Google Drive
```

### What's Stored Where

**Google Drive (appDataFolder)**:
- Encrypted vault file
- Salt (needed for decryption)
- Iteration count
- Encrypted data

**Device Secure Storage** (if biometrics enabled):
- Derived encryption key (encrypted by device hardware)
- Only accessible with fingerprint/FaceID

**Never Stored Anywhere**:
- Your master password (plain text)
- Decrypted vault data (except in RAM during active session)

---

**Last Updated**: 2025-12-25
