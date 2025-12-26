import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'auth_service.dart';

class DriveService {
  final AuthService _authService;
  drive.DriveApi? _driveApi;
  static const String _fileName = 'vault.json';

  DriveService(this._authService);

  Future<drive.DriveApi?> get _api async {
    if (_driveApi != null) return _driveApi!;
    final client = await _authService.getHttpClient();
    if (client != null) {
      _driveApi = drive.DriveApi(client);
    }
    return _driveApi;
  }

  void reset() {
    _driveApi = null;
  }

  Future<drive.File?> getVaultFile() async {
    final api = await _api;
    if (api == null) {
      throw Exception(
        'Google Drive API not initialized. Check internet or Logout/Login.',
      );
    }

    try {
      final fileList = await api.files.list(
        q: "name = '$_fileName' and trashed = false",
        spaces: 'appDataFolder',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first;
      }
      // Explicitly return null if confirmed not found
      return null;
    } catch (e) {
      if (kDebugMode) print('Error finding vault: $e');
      // Rethrow to distinguish from "Not Found"
      throw Exception('Failed to connect to Google Drive: $e');
    }
  }

  Future<String?> getVaultContent(String fileId) async {
    final api = await _api;
    if (api == null) return null;

    try {
      final media =
          await api.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }
      return utf8.decode(dataStore);
    } catch (e) {
      if (kDebugMode) print('Error reading vault: $e');
      return null;
    }
  }

  Future<String?> createVault(String initialContent) async {
    final api = await _api;
    if (api == null) {
      if (kDebugMode) print('Error creating vault: Drive API not initialized');
      return null;
    }

    try {
      if (kDebugMode) print('Creating new vault file...');
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
      if (kDebugMode) print('Vault created successfully with ID: ${file.id}');
      return file.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating vault: $e');
        if (e.toString().contains('SocketException') ||
            e.toString().contains('NetworkException')) {
          print('Network error detected');
        }
      }
      return null;
    }
  }

  Future<bool> updateVault(String fileId, String content) async {
    final api = await _api;
    if (api == null) {
      if (kDebugMode) print('Error updating vault: Drive API not initialized');
      return false;
    }

    try {
      if (kDebugMode) print('Updating vault file: $fileId');
      final uploadMedia = drive.Media(
        Stream.value(utf8.encode(content)),
        utf8.encode(content).length,
      );

      await api.files.update(drive.File(), fileId, uploadMedia: uploadMedia);
      if (kDebugMode) print('Vault updated successfully');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vault: $e');
        if (e.toString().contains('SocketException') ||
            e.toString().contains('NetworkException')) {
          print('Network error: Please check your internet connection');
        } else if (e.toString().contains('404')) {
          print('Vault file not found on Drive');
        } else if (e.toString().contains('403')) {
          print('Permission denied: Please re-authenticate');
        }
      }
      return false;
    }
  }

  /// Get Google Drive storage quota information
  Future<StorageQuota?> getStorageQuota() async {
    final api = await _api;
    if (api == null) {
      if (kDebugMode) print('Error getting storage: Drive API not initialized');
      return null;
    }

    try {
      if (kDebugMode) print('Fetching storage quota...');
      final about = await api.about.get($fields: 'storageQuota');

      if (about.storageQuota != null) {
        final quota = about.storageQuota!;
        final limit = int.tryParse(quota.limit ?? '0') ?? 0;
        final usage = int.tryParse(quota.usage ?? '0') ?? 0;

        if (kDebugMode) {
          print(
            'Storage - Used: ${_formatBytes(usage)}, Total: ${_formatBytes(limit)}',
          );
        }

        return StorageQuota(
          limit: limit,
          usage: usage,
          usageInDrive: int.tryParse(quota.usageInDrive ?? '0') ?? 0,
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting storage quota: $e');
      return null;
    }
  }

  /// Format bytes to human-readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Storage quota information from Google Drive
class StorageQuota {
  final int limit;
  final int usage;
  final int usageInDrive;

  StorageQuota({
    required this.limit,
    required this.usage,
    required this.usageInDrive,
  });

  int get available => limit - usage;
  double get usagePercentage => limit > 0 ? (usage / limit) * 100 : 0;

  String get usedFormatted => _formatBytes(usage);
  String get limitFormatted => _formatBytes(limit);
  String get availableFormatted => _formatBytes(available);

  bool get isLow => available < 10 * 1024 * 1024; // Less than 10MB
  bool get isCritical => available < 1 * 1024 * 1024; // Less than 1MB

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
