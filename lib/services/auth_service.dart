import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope,
      drive.DriveApi.driveMetadataReadonlyScope, // For storage quota
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  bool _manuallyLoggedOut = false;
  bool get manuallyLoggedOut => _manuallyLoggedOut;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  late Future<void> initialization;

  AuthService() {
    initialization = _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final wasLoggedIn = prefs.getBool('is_logged_in') ?? false;

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      if (account != null) {
        prefs.setBool('is_logged_in', true);
      }
      notifyListeners();
    });

    try {
      if (wasLoggedIn) {
        // If they were logged in before, we MUST wait for silent sign-in
        await _googleSignIn.signInSilently();
      }
    } catch (e) {
      if (kDebugMode) print('Silent sign in error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> signIn() async {
    try {
      _manuallyLoggedOut = false;

      // Wrap in Future.microtask to avoid main thread deadlock
      final account = await Future.microtask(() => _googleSignIn.signIn());

      if (account != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Platform exception during sign in: ${e.message}');
      }
      // Rethrow with more context
      throw Exception('Google Sign-In failed: ${e.message ?? "Unknown error"}');
    } catch (error) {
      if (kDebugMode) {
        print('Sign in failed: $error');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    _manuallyLoggedOut = true;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);

    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      await _googleSignIn.signOut();
    }
    notifyListeners();
  }

  /// Returns an authenticated HTTP client for use with Google APIs
  Future<dynamic> getHttpClient() async {
    return await _googleSignIn.authenticatedClient();
  }
}
