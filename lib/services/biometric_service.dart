import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _isBiometricAvailable = false;
  bool get isBiometricAvailable => _isBiometricAvailable;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  late Future<void> initialization;

  BiometricService() {
    initialization = _init();
  }

  Future<void> _init() async {
    await _checkAvailability();
    await _checkIfEnabled();
  }

  Future<void> _checkAvailability() async {
    try {
      // ignore: deprecated_member_use
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      _isBiometricAvailable = canAuthenticate;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Biometric check failed: $e');
      }
    }
  }

  Future<void> _checkIfEnabled() async {
    String? enabled = await _storage.read(key: 'biometric_enabled');
    _isEnabled = enabled == 'true';
    notifyListeners();
  }

  Future<bool> authenticate() async {
    if (!_isBiometricAvailable) return false;

    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Mero Vault',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Authentication failed: $e');
      }
      return false;
    }
  }

  Future<bool> enableBiometrics(String masterKey) async {
    final authenticated = await authenticate();
    if (!authenticated) return false;

    await _storage.write(key: 'biometric_enabled', value: 'true');
    await _storage.write(key: 'master_key', value: masterKey);
    _isEnabled = true;
    notifyListeners();
    return true;
  }

  Future<String?> getMasterKey() async {
    final authenticated = await authenticate();
    if (!authenticated) return null;

    return await _storage.read(key: 'master_key');
  }

  Future<void> disableBiometrics() async {
    await _storage.delete(key: 'biometric_enabled');
    await _storage.delete(key: 'master_key');
    _isEnabled = false;
    notifyListeners();
  }
}
