import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/vault_entry.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/branded_app_bar.dart';
import 'add_entry_screen.dart';
import '../../utils/transitions.dart';
import '../../utils/security_utils.dart';
import '../../widgets/toast_notification.dart';

class EntryDetailScreen extends StatelessWidget {
  final String entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultProvider>(
      builder: (context, vaultProvider, _) {
        final entry = vaultProvider.vaultData?.entries.firstWhere(
          (e) => e.id == entryId,
          orElse: () => VaultEntry(
            id: '',
            title: 'Not Found',
            fields: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (entry!.id.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: BrandedAppBar(title: 'MERO VAULT', showLogo: true),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                SlideUpPageRoute(child: const AddEntryScreen()),
              );
            },
            backgroundColor: const Color(0xFFD32F2F),
            tooltip: 'Add New Entry',
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Card Header with Title and Actions
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3436),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 20,
                                    ),
                                    color: Colors.grey[600],
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () async {
                                      final authenticated =
                                          await SecurityUtils.authenticate(
                                            context,
                                          );

                                      if (authenticated && context.mounted) {
                                        Navigator.push(
                                          context,
                                          SlideUpPageRoute(
                                            child: AddEntryScreen(
                                              entryToEdit: entry,
                                            ),
                                          ),
                                        );
                                      } else if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Authentication required to edit entries',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                    ),
                                    color: Colors.red[400],
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _confirmDelete(context, entry),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              for (int i = 0; i < entry.fields.length; i++) ...[
                                _buildDetailItem(context, entry.fields[i]),
                                if (i < entry.fields.length - 1)
                                  const Divider(
                                    indent: 64,
                                    endIndent: 16,
                                    height: 1,
                                    thickness: 0.5,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last Updated: ${entry.updatedAt.toLocal().toString().split('.').first}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(BuildContext context, VaultField field) {
    final isPassword = field.label.toLowerCase().contains('password');
    final isPin = field.label.toLowerCase().contains('pin');
    final isTransaction = field.label.toLowerCase().contains('transaction');
    final isEmail =
        field.label.toLowerCase().contains('email') ||
        field.label.toLowerCase().contains('user');

    IconData iconData = Icons.info_outline_rounded;
    if (isPassword) iconData = Icons.vpn_key_rounded;
    if (isEmail) iconData = Icons.alternate_email_rounded;
    if (field.label.toLowerCase().contains('url'))
      iconData = Icons.link_rounded;
    if (field.label.toLowerCase().contains('note'))
      iconData = Icons.notes_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: const Color(0xFFD32F2F), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (field.isObscured && (isPassword || isPin || isTransaction))
                      ? '••••••••••••'
                      : field.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (field.isObscured && (isPassword || isPin || isTransaction))
            IconButton(
              icon: const Icon(Icons.visibility_rounded, size: 20),
              color: Colors.grey,
              onPressed: () async {
                final authenticated = await SecurityUtils.authenticate(context);

                if (authenticated && context.mounted) {
                  _showRevealedValue(context, field);
                } else if (context.mounted) {
                  ToastNotification.show(
                    context,
                    'Authentication failed',
                    isError: true,
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: const Color(0xFF0066CC),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: field.value));
              ToastNotification.show(context, 'Copied to clipboard');
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, VaultEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text(
          'Are you sure you want to remove this? This action requires biometric or master password verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authenticated = await SecurityUtils.authenticate(context);

      if (authenticated && context.mounted) {
        await Provider.of<VaultProvider>(
          context,
          listen: false,
        ).deleteEntry(entry.id);
        Navigator.pop(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletion aborted. Authentication failed.'),
          ),
        );
      }
    }
  }

  void _showRevealedValue(BuildContext context, VaultField field) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFFD32F2F),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                field.label.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SelectableText(
                  field.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: field.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            behavior: SnackBarBehavior.floating,
                            width: 200,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('COPY'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0066CC),
                        side: const BorderSide(color: Color(0xFF0066CC)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('DONE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
