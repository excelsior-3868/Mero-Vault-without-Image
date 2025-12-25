import 'dart:convert';
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
      print('Error finding vault: $e');
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
      print('Error reading vault: $e');
      return null;
    }
  }

  Future<String?> createVault(String initialContent) async {
    final api = await _api;
    if (api == null) return null;

    try {
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
      return file.id;
    } catch (e) {
      print('Error creating vault: $e');
      return null;
    }
  }

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
      print('Error updating vault: $e');
      return false;
    }
  }
}
