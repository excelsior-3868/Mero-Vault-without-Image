import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/unlock_screen.dart';
import 'features/splash/initialization_screen.dart';
import 'providers/vault_provider.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/drive_service.dart';
import 'services/encryption_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeroVaultApp());
}

class MeroVaultApp extends StatelessWidget {
  const MeroVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BiometricService()),
        Provider(create: (_) => EncryptionService()), 
        ProxyProvider<AuthService, DriveService>(
          update: (_, auth, __) => DriveService(auth),
        ),
        ChangeNotifierProvider<VaultProvider>(
          create: (context) {
             final drive = Provider.of<DriveService>(context, listen: false);
             final encryption = Provider.of<EncryptionService>(context, listen: false);
             return VaultProvider(drive, encryption);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Mero Vault',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD32F2F), // Red
            primary: const Color(0xFFD32F2F),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.currentUser != null) {
          // Logged in, check vault status
          return const InitializationScreen();
        } else {
          // Not logged in, go to Login Screen
          return const LoginScreen();
        }
      },
    );
  }
}
