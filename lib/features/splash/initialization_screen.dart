import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/create_vault_screen.dart';
import '../../widgets/toast_notification.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../providers/vault_provider.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  bool _isChecking = true;
  String _statusMessage = 'Initializing...';
  final _passwordController = TextEditingController();
  bool _showPasswordInput = false;
  bool _isVaultSyncing = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final biometrics = Provider.of<BiometricService>(context, listen: false);
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking Security Settings...';
    });

    await Future.wait([auth.initialization, biometrics.initialization]);

    // Check if vault exists first
    await vaultProvider.checkVaultExistence();

    _checkVaultState();
  }

  Future<void> _checkVaultState() async {
    final biometrics = Provider.of<BiometricService>(context, listen: false);
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

    if (vaultProvider.status == VaultStatus.notFound) {
      // AuthWrapper will handle navigation to CreateVaultScreen
      return;
    }

    if (vaultProvider.status == VaultStatus.found) {
      setState(() {
        _isChecking = true;
        _statusMessage = 'Syncing Secure Vault...';
      });

      // Try biometric unlock if enabled
      if (biometrics.isEnabled) {
        final masterKeyBase64 = await biometrics.getMasterKey();
        if (masterKeyBase64 != null) {
          final key = base64Decode(masterKeyBase64);
          final success = await vaultProvider.unlockWithKey(key);
          if (success) return; // AuthWrapper will navigate to Dashboard
        }
      }

      // Fallback: Show password input
      if (mounted) {
        setState(() {
          _isChecking = false;
          _showPasswordInput = true;
          _statusMessage = 'Master Password Required';
        });
      }
    } else if (vaultProvider.status == VaultStatus.error) {
      setState(() {
        _isChecking = false;
        _statusMessage =
            vaultProvider.errorMessage ?? 'Error connecting to Drive';
      });
    }
  }

  Future<void> _unlockWithPassword() async {
    FocusScope.of(context).unfocus();
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() {
      _isVaultSyncing = true;
      _statusMessage = 'Decrypting...';
    });

    try {
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      final success = await vaultProvider.unlock(password);

      if (success && mounted) {
      } else {
        if (mounted) {
          final error =
              vaultProvider.errorMessage ?? 'Incorrect Master Password';
          ToastNotification.show(
            context,
            error.contains('Decryption failed')
                ? 'Incorrect Master Password'
                : error,
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unlock failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isVaultSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFD32F2F);
    final biometrics = Provider.of<BiometricService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo',
                  child: Image.asset('assets/images/logo.png', width: 100),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MERO VAULT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: primaryRed,
                  ),
                ),
                const SizedBox(height: 64),
                if (_isChecking || _isVaultSyncing) ...[
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _statusMessage.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ] else if (_showPasswordInput) ...[
                  const Text(
                    'SECURE UNLOCK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                        color: primaryRed,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _unlockWithPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('UNLOCK VAULT'),
                  ),
                  if (biometrics.isEnabled) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _checkVaultState,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.fingerprint_rounded,
                              color: primaryRed,
                              size: 40,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UNLOCK WITH BIOMETRICS',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateVaultScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'FORGOT PASSWORD? CREATE NEW VAULT',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ] else ...[
                  // Error or manually logged out state
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _startInitialization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('RETRY'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final auth = Provider.of<AuthService>(
                        context,
                        listen: false,
                      );
                      final vault = Provider.of<VaultProvider>(
                        context,
                        listen: false,
                      );
                      final bio = Provider.of<BiometricService>(
                        context,
                        listen: false,
                      );
                      await bio.disableBiometrics();
                      vault.clear();
                      await auth.signOut();
                    },
                    child: Text(
                      'SIGN OUT',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
