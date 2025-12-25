import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/branded_app_bar.dart';
import '../../widgets/toast_notification.dart';
import '../auth/create_vault_screen.dart';
import '../../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    final vaultProvider = Provider.of<VaultProvider>(context);
    final vaultName = vaultProvider.vaultData?.vaultName ?? 'No Vault Loaded';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const BrandedAppBar(title: 'MERO VAULT'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserSummary(context, user),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildSectionHeader('VAULT INFO'),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFFD32F2F),
                      title: 'Vault Name',
                      subtitle: vaultName,
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader('SECURITY'),
                  _buildMenuCard([
                    _buildBiometricToggle(context),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.refresh_rounded,
                      color: Colors.orange,
                      title: 'Reset & Create New Vault',
                      subtitle: 'Warning: Overwrites existing data',
                      onTap: () => _showResetDialog(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      color: Colors.redAccent,
                      title: 'Logout',
                      subtitle: 'Sign out of Mero Vault safely',
                      onTap: () => _showLogoutDialog(context, authService),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader('ABOUT'),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      color: Colors.grey,
                      title: 'App Version',
                      subtitle: 'v1.2.0 (Stable)',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.code_rounded,
                      color: Colors.grey,
                      title: 'Developer',
                      subtitle: 'Subin Bajracharya',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSummary(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFD32F2F), // Matches App Theme Red
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.grey[200],
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Guest User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'Not signed in',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildBiometricToggle(BuildContext context) {
    final bioService = Provider.of<BiometricService>(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0066CC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.fingerprint_rounded,
          color: Color(0xFF0066CC),
          size: 22,
        ),
      ),
      title: const Text(
        'Biometric Unlock',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: const Text(
        'Use fingerprint to secure your vault',
        style: TextStyle(fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: bioService.isEnabled,
        activeColor: const Color(0xFFD32F2F),
        onChanged: (bool value) async {
          if (value) {
            final vaultProvider = Provider.of<VaultProvider>(
              context,
              listen: false,
            );
            final masterKey = vaultProvider.currentMasterKeyBase64;

            if (masterKey != null) {
              final success = await bioService.enableBiometrics(masterKey);
              if (context.mounted) {
                ToastNotification.show(
                  context,
                  success
                      ? 'Biometrics enabled successfully!'
                      : 'Failed to enable biometrics.',
                  isError: !success,
                );
              }
            } else {
              if (context.mounted) {
                ToastNotification.show(
                  context,
                  'Unlock vault first to enable biometrics',
                  isError: true,
                );
              }
            }
          } else {
            await bioService.disableBiometrics();
            if (context.mounted) {
              ToastNotification.show(context, 'Biometrics disabled.');
            }
          }
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
          'This will permanently delete your current vault data from Google Drive and let you create a new one. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _authenticateForReset(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Authenticate to Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateForReset(BuildContext context) async {
    final bioService = Provider.of<BiometricService>(context, listen: false);
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

    bool authenticated = false;

    // 1. Try Biometrics if enabled
    if (bioService.isEnabled) {
      authenticated = await bioService.authenticate();
    }

    // 2. If not bio enabled or bio fails, ask for Master Password
    if (!authenticated && context.mounted) {
      final password = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Verify Master Password'),
            content: TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Enter Master Password',
                hintText: 'Required to confirm reset',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Verify'),
              ),
            ],
          );
        },
      );

      if (password != null && password.isNotEmpty) {
        // Simple verification: try to unlock (effectively re-verifying)
        // Since we are already unlocked, we can just check if the password is correct
        // but the easiest way is to let the user know we're checking.
        authenticated = await vaultProvider.unlock(password);
      }
    }

    if (authenticated && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateVaultScreen()),
      );
    } else if (context.mounted) {
      ToastNotification.show(
        context,
        'Authentication failed. Reset cancelled.',
        isError: true,
      );
    }
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to sign out? Your biometric settings will be reset for security.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Dismiss dialog
              final bioService = Provider.of<BiometricService>(
                context,
                listen: false,
              );
              final vaultProvider = Provider.of<VaultProvider>(
                context,
                listen: false,
              );

              await bioService.disableBiometrics();
              vaultProvider.clear();
              await authService.signOut();
              if (context.mounted) {
                // Hard reset the app to the first screen (AuthWrapper)
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
