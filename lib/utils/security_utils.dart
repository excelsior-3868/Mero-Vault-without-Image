import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../services/biometric_service.dart';

class SecurityUtils {
  static Future<bool> authenticate(BuildContext context) async {
    final bioService = Provider.of<BiometricService>(context, listen: false);
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

    // 1. Try biometrics if enabled
    if (bioService.isEnabled) {
      final success = await bioService.authenticate();
      if (success) return true;
    }

    // 2. Fallback to Master Password dialog
    if (context.mounted) {
      final password = await showPasswordVerificationDialog(context);
      if (password != null && password.isNotEmpty) {
        return vaultProvider.verifyPassword(password);
      }
    }

    return false;
  }

  static Future<String?> showPasswordVerificationDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController();
        bool isVisible = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.security_rounded, color: Color(0xFFD32F2F)),
                  SizedBox(width: 12),
                  Text('Verify Identity'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please enter your Master Password to proceed with this sensitive action.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    obscureText: !isVisible,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () =>
                            setDialogState(() => isVisible = !isVisible),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (val) => Navigator.pop(context, val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('VERIFY'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
