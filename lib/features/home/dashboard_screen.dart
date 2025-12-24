import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/vault_provider.dart';
import '../../services/auth_service.dart';
import '../splash/initialization_screen.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';
import '../../models/vault_entry.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultProvider = Provider.of<VaultProvider>(context);
    final vaultData = vaultProvider.vaultData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mero Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (context.mounted) {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const InitializationScreen()),
                 );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEntryDialog(context);
        },
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.add),
      ),
      body: vaultData == null 
          ? const Center(child: CircularProgressIndicator())
          : vaultData.entries.isEmpty
              ? const Center(child: Text('No passwords yet. Add one!'))
              : ListView.builder(
                  itemCount: vaultData.entries.length,
                  itemBuilder: (context, index) {
                    final entry = vaultData.entries[index];
                    
                    // Try to find a field to show as subtitle (e.g. Username)
                    String? subtitle;
                    try {
                      final usernameField = entry.fields.firstWhere(
                        (f) => f.label.toLowerCase().contains('username') || f.label.toLowerCase().contains('email'),
                      );
                      subtitle = usernameField.value;
                    } catch (_) {
                       subtitle = 'Active';
                    }

                    // Try to find a password field for quick copy
                    VaultField? passwordField;
                    try {
                      passwordField = entry.fields.firstWhere(
                        (f) => f.isObscured || f.label.toLowerCase().contains('password'),
                      );
                    } catch (_) {}

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.lock),
                      ),
                      title: Text(entry.title),
                      subtitle: Text(subtitle ?? ''),
                      trailing: passwordField != null ? IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: passwordField!.value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password copied to clipboard')),
                          );
                        },
                      ) : null,
                      onTap: () {
                        // View Details
                         _showEntryDetails(context, entry);
                      },
                    );
                  },
                ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEntryScreen()),
    );
  }

  void _showEntryDetails(BuildContext context, VaultEntry entry) {
     Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
    );
  }
}
