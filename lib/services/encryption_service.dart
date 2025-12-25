import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static const int iterations = 150000;
  static const int keyLength = 32; // 256 bits

  /// Derives a 32-byte key from the password and salt using PBKDF2-HMAC-SHA256.
  Uint8List deriveKey(String password, Uint8List salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: () => sha256,
      iterations: iterations,
      bits: keyLength * 8,
    );
    return Uint8List.fromList(
      pbkdf2.deriveKeySync(Uint8List.fromList(utf8.encode(password)), salt),
    );
  }

  /// Encrypts plainText using the derived key.
  /// Returns format "iv:ciphertext" (both base64).
  String encrypt(String plainText, Uint8List keyBytes) {
    final key = Key(keyBytes);
    final iv = IV.fromLength(12); // GCM standard IV length is 12 bytes
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts "iv:ciphertext" using the derived key.
  String decrypt(String encryptedString, Uint8List keyBytes) {
    try {
      final parts = encryptedString.split(':');
      if (parts.length != 2) throw Exception('Invalid encrypted format');

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final key = Key(keyBytes);
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generates a random salt.
  Uint8List generateSalt() {
    return IV.fromLength(16).bytes;
  }
}

/// Helper class for PBKDF2 if not available in the library as direct sync
class Pbkdf2 {
  final Hash Function() macAlgorithm;
  final int iterations;
  final int bits;

  Pbkdf2({
    required this.macAlgorithm,
    required this.iterations,
    required this.bits,
  });

  List<int> deriveKeySync(List<int> password, List<int> salt) {
    final hmac = Hmac(macAlgorithm(), password);
    final key = <int>[];
    int blockIndex = 1;

    while (key.length < (bits / 8)) {
      var lastBlock = hmac.convert(salt + _int32ToBytes(blockIndex)).bytes;
      var xorSum = List<int>.from(lastBlock);

      for (int i = 1; i < iterations; i++) {
        lastBlock = hmac.convert(lastBlock).bytes;
        for (int j = 0; j < xorSum.length; j++) {
          xorSum[j] ^= lastBlock[j];
        }
      }

      key.addAll(xorSum);
      blockIndex++;
    }

    return key.sublist(0, (bits / 8).floor());
  }

  List<int> _int32ToBytes(int value) {
    final bytes = Uint8List(4);
    final data = ByteData.view(bytes.buffer);
    data.setUint32(0, value, Endian.big);
    return bytes;
  }
}
