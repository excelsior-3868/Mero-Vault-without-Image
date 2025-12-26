import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/drive_service.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/branded_app_bar.dart';
import '../../widgets/toast_notification.dart';
import '../auth/create_vault_screen.dart';
import '../../main.dart';
import 'about_app_screen.dart';

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
                      icon: Icons.download_rounded,
                      color: const Color(0xFF0066CC),
                      title: 'Export Vault',
                      subtitle: 'Download vault as readable JSON',
                      onTap: () => _exportVault(context),
                    ),
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
                  _buildSectionHeader('GOOGLE DRIVE STORAGE'),
                  _buildStorageCard(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('ABOUT'),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      color: const Color(0xFF0066CC),
                      title: 'About Mero Vault',
                      subtitle: 'App info, features & security',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutAppScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.code_rounded,
                      color: Colors.grey,
                      title: 'App Version',
                      subtitle: 'v1.0.0 (Stable)',
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

  Widget _buildStorageCard(BuildContext context) {
    final driveService = Provider.of<DriveService>(context, listen: false);

    return FutureBuilder<StorageQuota?>(
      future: driveService.getStorageQuota(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unable to fetch storage info',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        final quota = snapshot.data!;
        final percentage = quota.usagePercentage;
        Color progressColor = const Color(0xFF4CAF50); // Green
        if (quota.isCritical) {
          progressColor = Colors.red;
        } else if (quota.isLow) {
          progressColor = Colors.orange;
        }

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_rounded,
                      color: Color(0xFF0066CC),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Storage Usage',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${quota.usedFormatted} of ${quota.limitFormatted} used',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${quota.availableFormatted} available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (quota.isLow)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: quota.isCritical
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: quota.isCritical
                              ? Colors.red.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Text(
                        quota.isCritical ? 'CRITICAL' : 'LOW',
                        style: TextStyle(
                          color: quota.isCritical
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
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

  Future<void> _exportVault(BuildContext context) async {
    try {
      // Require authentication before export
      final bioService = Provider.of<BiometricService>(context, listen: false);
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

      bool authenticated = false;

      // Try biometric authentication first
      if (bioService.isEnabled) {
        authenticated = await bioService.authenticate();
      }

      // If biometric fails or not enabled, ask for master password
      if (!authenticated && context.mounted) {
        final password = await showDialog<String>(
          context: context,
          builder: (context) {
            final controller = TextEditingController();
            return AlertDialog(
              title: const Text('Verify Master Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your master password to export vault data.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Master Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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
          authenticated = await vaultProvider.unlock(password);
        }
      }

      if (!authenticated) {
        if (context.mounted) {
          ToastNotification.show(
            context,
            'Authentication failed. Export cancelled.',
            isError: true,
          );
        }
        return;
      }

      // Ask user to choose format
      if (!context.mounted) return;
      final format = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Export Format'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.code, color: Color(0xFF0066CC)),
                title: const Text('JSON'),
                subtitle: const Text('Structured data format'),
                onTap: () => Navigator.pop(context, 'json'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.text_fields,
                  color: Color(0xFF4CAF50),
                ),
                title: const Text('TXT'),
                subtitle: const Text('Plain text format'),
                onTap: () => Navigator.pop(context, 'txt'),
              ),
            ],
          ),
        ),
      );

      if (format == null || !context.mounted) return;

      // Export vault
      if (context.mounted) {
        ToastNotification.show(context, 'Exporting vault...');
      }

      final String exportString;
      final String fileName;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

      if (format == 'txt') {
        exportString = vaultProvider.exportVaultAsTxt();
        fileName = 'mero_vault_export_$timestamp.txt';
      } else {
        exportString = vaultProvider.exportVaultAsJson();
        fileName = 'mero_vault_export_$timestamp.json';
      }

      // Save directly to Downloads folder
      Directory? directory;

      if (Platform.isAndroid) {
        // For Android, use Downloads directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage
          directory = await getExternalStorageDirectory();
        }
      } else {
        // For other platforms, use documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(exportString);

      if (context.mounted) {
        ToastNotification.show(
          context,
          'Vault exported to Downloads/$fileName',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastNotification.show(
          context,
          'Export failed: ${e.toString()}',
          isError: true,
        );
      }
    }
  }
}
