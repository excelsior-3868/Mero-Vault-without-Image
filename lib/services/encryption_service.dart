import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class EncryptionService {
  // Encrypts plainText using the password. Returns format "iv:ciphertext" (both base64).
  String encrypt(String plainText, String password) {
    final key = Key.fromUtf8(padKey(password));
    final iv = IV.fromLength(16); // Random IV
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    return '${iv.base64}:${encrypted.base64}';
  }

  // Decrypts "iv:ciphertext" using the password.
  String decrypt(String encryptedString, String password) {
    try {
      final parts = encryptedString.split(':');
      if (parts.length != 2) throw Exception('Invalid encrypted format');
      
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      
      final key = Key.fromUtf8(padKey(password));
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  String padKey(String password) {
    if (password.length >= 32) {
      return password.substring(0, 32);
    }
    return password.padRight(32, '#');
  }
}
