import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'auth_service.dart';

class DriveService {
  final AuthService _authService;
  drive.DriveApi? _driveApi;
  static const String _fileName = 'securevault.json';

  DriveService(this._authService);

  Future<drive.DriveApi?> get _api async {
    if (_driveApi != null) return _driveApi!;
    final client = await _authService.getHttpClient();
    if (client != null) {
      _driveApi = drive.DriveApi(client);
    }
    return _driveApi;
  }

  Future<drive.File?> getVaultFile() async {
    final api = await _api;
    if (api == null) return null;

    try {
      final fileList = await api.files.list(
        q: "name = '$_fileName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime)',
      );
      
      if ((fileList.files?.length ?? 0) > 0) {
        return fileList.files!.first;
      }
    } catch (e) {
      print('Error finding vault: $e');
    }
    return null;
  }

  Future<String?> getVaultContent(String fileId) async {
    final api = await _api;
    if (api == null) return null;

    try {
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      
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

      final fileToUpload = drive.File()..name = _fileName;
      
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
}
