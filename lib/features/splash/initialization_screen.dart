import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/drive_service.dart';
import '../auth/login_screen.dart';
import '../auth/unlock_screen.dart';
import '../auth/create_vault_screen.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkState());
  }

  Future<void> _checkState() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final driveService = Provider.of<DriveService>(context, listen: false);

    // 1. Check Auth
    // Wait a brief moment for auth stream to settle if needed, but currentUser should be updated by AuthService constructor?
    // Actually, AuthService calls signInSilently which is async. We might need to wait for it.
    // Better: listen to auth state changes in the UI or use a stream builder.
    // However, for this check, let's assume if currentUser is null after a delay, we aren't logged in.
    
    // Actually, AuthService is a ChangeNotifier. We can just check `currentUser`.
    // But `signInSilently` takes time.
    
    // Let's rely on the user being on this screen meaning we need to check.
    // We should probably show a spinner while checking.
    
    // NOTE: signInSilently might return null if not signed in.
    
    // Ideally, AuthService should expose a "loading" state.
    // For now, let's just check `initialAuthCheck` future if we added one, or just check `googleSignIn.isSignedIn()`.
    // Since we don't have that exposed easily, let's wait a bit or improve AuthService.
    // I'll update AuthService to have an `isReady` future or similar. For now, I'll assume if it's null, we go to login.
    
    // BUT, if `signInSilently` is still running, we might prematurely show Login.
    // The proper way is to listen to the google_sign_in stream which we do in AuthService.
    
    // Let's assume the AuthWrapper in main.dart handles the "Logged In vs Not Logged In" switch.
    // If we are HERE (InitializationScreen), it implies we ARE logged in (if we use it as a child of AuthWrapper's "Logged In" branch).
    // Let's double check main.dart.
    
    // In main.dart:
    // if (authService.currentUser != null) return const InitializationScreen();
    // else return const LoginScreen();
    
    // So if we are here, we are logged in.
    
    // 2. Check Drive for Vault
    try {
      final vaultFile = await driveService.getVaultFile();
      
      if (!mounted) return;

      if (vaultFile != null) {
        // Vault exists -> Unlock
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UnlockScreen()),
        );
      } else {
        // Vault does not exist -> Create
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CreateVaultScreen()),
        );
      }
    } catch (e) {
      // Handle error (e.g., network issue)
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking vault: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD32F2F)),
            SizedBox(height: 16),
            Text('Syncing with your Safe...'),
          ],
        ),
      ),
    );
  }
}
