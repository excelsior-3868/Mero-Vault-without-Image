import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/vault_entry.dart';
import '../../providers/vault_provider.dart';
import 'add_entry_screen.dart';

class EntryDetailScreen extends StatelessWidget {
  final VaultEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEntryScreen(entryToEdit: entry),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Entry?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await Provider.of<VaultProvider>(context, listen: false).deleteEntry(entry.id);
                Navigator.pop(context); // Close detail screen
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: entry.fields.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final field = entry.fields[index];
                  return _buildDetailItem(context, field);
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Last Updated: ${entry.updatedAt.toLocal().toString().split('.').first}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, VaultField field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  field.isObscured ? '••••••••' : field.value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              if (field.isObscured)
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                     // Show password in SnackBar
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('${field.label}: ${field.value}'), duration: const Duration(seconds: 3)),
                     );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: field.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
