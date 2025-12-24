import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

class BiometricService extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isBiometricAvailable = false;
  bool get isBiometricAvailable => _isBiometricAvailable;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  BiometricService() {
    _checkAvailability();
    _checkIfEnabled();
  }

  Future<void> _checkAvailability() async {
    try {
      // ignore: deprecated_member_use
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
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
      );
    } catch (e) {
      if (kDebugMode) {
        print('Authentication failed: $e');
      }
      return false;
    }
  }

  Future<void> enableBiometrics() async {
    await _storage.write(key: 'biometric_enabled', value: 'true');
    _isEnabled = true;
    notifyListeners();
  }

  Future<void> disableBiometrics() async {
    await _storage.delete(key: 'biometric_enabled');
    _isEnabled = false;
    notifyListeners();
  }
}
