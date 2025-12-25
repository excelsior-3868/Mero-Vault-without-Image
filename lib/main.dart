import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/initialization_screen.dart';
import 'features/auth/create_vault_screen.dart';
import 'providers/vault_provider.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/drive_service.dart';
import 'services/encryption_service.dart';
import 'features/navigation/nav_bar_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeroVaultApp());
}

class MeroVaultApp extends StatefulWidget {
  const MeroVaultApp({super.key});

  @override
  State<MeroVaultApp> createState() => _MeroVaultAppState();
}

class _MeroVaultAppState extends State<MeroVaultApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Auto-lock the vault when app goes to background
      final provider = Provider.of<VaultProvider>(context, listen: false);
      provider.clear();
    }
  }

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
            final encryption = Provider.of<EncryptionService>(
              context,
              listen: false,
            );
            return VaultProvider(drive, encryption);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Mero Vault',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD32F2F), // Professional Red
            primary: const Color(0xFFD32F2F),
            secondary: const Color(0xFF0066CC), // Professional Blue
            surface: Colors.white,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const SplashScreen(nextScreen: AuthWrapper()),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, VaultProvider>(
      builder: (context, auth, vault, _) {
        return FutureBuilder(
          future: auth.initialization,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFD32F2F),
                    ),
                  ),
                ),
              );
            }

            // 1. Is user logged out of Google?
            if (auth.currentUser == null) {
              return const LoginScreen();
            }

            // 2. Switch Based on Vault State
            switch (vault.status) {
              case VaultStatus.unlocked:
                return const NavBarWrapper();
              case VaultStatus.notFound:
                return const CreateVaultScreen();
              case VaultStatus.initial:
              case VaultStatus.checking:
              case VaultStatus.found:
              case VaultStatus.error:
                return const InitializationScreen();
            }
          },
        );
      },
    );
  }
}
