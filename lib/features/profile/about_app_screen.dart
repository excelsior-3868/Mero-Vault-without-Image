import 'package:flutter/material.dart';
import '../../widgets/branded_app_bar.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const BrandedAppBar(title: 'ABOUT MERO VAULT'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Column(
                children: [
                  // Use actual logo instead of icon
                  Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mero Vault',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your Personal Password Manager',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description
            _buildSection(
              title: 'DESCRIPTION',
              child: const Text(
                'A secure, encrypted password manager that stores your sensitive information safely in your Google Drive. All data is encrypted using AES-256-GCM encryption before being stored, ensuring your passwords and credentials remain private and secure.',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ),

            // Key Features
            _buildSection(
              title: 'KEY FEATURES',
              child: Column(
                children: [
                  _buildFeatureItem(
                    Icons.lock_rounded,
                    'End-to-End Encryption',
                    'Your data is encrypted on your device before upload',
                  ),
                  _buildFeatureItem(
                    Icons.vpn_key_rounded,
                    'Master Password',
                    'Single password to access all your credentials',
                  ),
                  _buildFeatureItem(
                    Icons.fingerprint_rounded,
                    'Biometric Authentication',
                    'Quick access with fingerprint/face recognition',
                  ),
                  _buildFeatureItem(
                    Icons.cloud_rounded,
                    'Google Drive Sync',
                    'Your encrypted vault syncs across devices',
                  ),
                  _buildFeatureItem(
                    Icons.dashboard_customize_rounded,
                    'Dynamic Fields',
                    'Create custom fields for any type of credential',
                  ),
                  _buildFeatureItem(
                    Icons.security_rounded,
                    'Sensitive Data Protection',
                    'Mark fields as sensitive for extra security',
                  ),
                ],
              ),
            ),

            // Security Information
            _buildSection(
              title: 'SECURITY',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecurityItem(
                    'AES-256-GCM Encryption',
                    'Military-grade encryption standard',
                  ),
                  _buildSecurityItem(
                    'PBKDF2 Key Derivation',
                    '100,000 iterations for strong key generation',
                  ),
                  _buildSecurityItem(
                    'Zero-Knowledge Architecture',
                    'We never see your master password or data',
                  ),
                  _buildSecurityItem(
                    'Auto-Lock',
                    'Vault locks when app goes to background',
                  ),
                ],
              ),
            ),

            // Important Reminders
            _buildSection(
              title: 'IMPORTANT REMINDERS',
              child: Column(
                children: [
                  _buildWarningCard(
                    Icons.warning_amber_rounded,
                    'NEVER FORGET YOUR MASTER PASSWORD',
                    'We cannot recover your master password. If forgotten, you\'ll need to create a new vault. Consider storing it in a safe place.',
                  ),
                  const SizedBox(height: 12),
                  _buildWarningCard(
                    Icons.backup_rounded,
                    'BACKUP YOUR VAULT',
                    'Your vault is stored in Google Drive. Ensure you have Google Drive backup enabled and export your vault periodically.',
                  ),
                  const SizedBox(height: 12),
                  _buildWarningCard(
                    Icons.system_update_rounded,
                    'KEEP APP UPDATED',
                    'Regular updates include security improvements. Enable auto-updates for best security.',
                  ),
                ],
              ),
            ),

            // Privacy
            _buildSection(
              title: 'PRIVACY',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacyItem(
                    'Your data is encrypted before leaving your device',
                  ),
                  _buildPrivacyItem(
                    'We don\'t have access to your master password',
                  ),
                  _buildPrivacyItem(
                    'We don\'t collect or store your personal information',
                  ),
                  _buildPrivacyItem(
                    'Your vault is stored in YOUR Google Drive account',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2025 Mero Vault',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built with Flutter',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0066CC), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF4CAF50),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_rounded,
            color: Color(0xFF0066CC),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
