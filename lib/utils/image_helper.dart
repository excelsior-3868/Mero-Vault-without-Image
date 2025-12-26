import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageHelper {
  /// Maximum image size in bytes (500KB)
  static const int maxSizeBytes = 500 * 1024;

  /// Maximum image dimensions
  static const int maxWidth = 1920;
  static const int maxHeight = 1920;

  /// Compress image to meet size requirements
  /// Returns compressed image bytes
  static Future<Uint8List> compressImage(Uint8List imageBytes) async {
    try {
      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
          interpolation: img.Interpolation.linear,
        );
      }

      // Start with quality 85
      int quality = 85;
      Uint8List compressed = Uint8List.fromList(
        img.encodeJpg(image, quality: quality),
      );

      // Reduce quality until size is acceptable
      while (compressed.length > maxSizeBytes && quality > 20) {
        quality -= 10;
        compressed = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      }

      // If still too large, resize more aggressively
      if (compressed.length > maxSizeBytes) {
        final scale = 0.8;
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
        compressed = Uint8List.fromList(img.encodeJpg(image, quality: 70));
      }

      return compressed;
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// Get human-readable file size
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
