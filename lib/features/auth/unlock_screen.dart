import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/biometric_service.dart';
import '../../providers/vault_provider.dart';
import '../home/dashboard_screen.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Attempt biometric unlock automatically if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  Future<void> _tryBiometricUnlock() async {
    final bioService = Provider.of<BiometricService>(context, listen: false);
    if (bioService.isEnabled) {
      final success = await bioService.authenticate();
      if (success) {
        if (mounted) {
          _unlockWithBiometrics();
        }
      }
    }
  }

  void _unlockWithBiometrics() {
    // TODO: Retrieve key from Secure Storage and unlock
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric verified! Unlocking...')),
    );
    // Navigate to Home
  }

  Future<void> _unlockWithPassword() async {
    setState(() => _isLoading = true);

    try {
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      final success = await vaultProvider.unlock(_passwordController.text);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Unlocked!')));
          // Navigate to Dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect Password or Error')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error unlocking: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bioService = Provider.of<BiometricService>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unlock Mero Vault',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _unlockWithPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Unlock'),
                ),
              if (bioService.isBiometricAvailable) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _tryBiometricUnlock,
                  icon: const Icon(Icons.fingerprint, size: 32),
                  label: const Text('Use Biometrics'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
