import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/branded_app_bar.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';
import '../../utils/transitions.dart';
import '../../models/vault_entry.dart';
import '../../utils/security_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Ensure keyboard is dismissed when navigating to dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultProvider = Provider.of<VaultProvider>(context);
    final vaultData = vaultProvider.vaultData;

    // Filtered entries
    final entries =
        vaultData?.entries.where((e) {
          final query = _searchQuery.toLowerCase();
          return e.title.toLowerCase().contains(query);
        }).toList() ??
        [];

    return Scaffold(
      appBar: BrandedAppBar(title: 'MERO VAULT'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEntryDialog(context);
        },
        backgroundColor: const Color(0xFFD32F2F),
        tooltip: 'Add New Entry',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: vaultData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Search Bar Section
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by title...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFD32F2F),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD32F2F),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Content section
                Expanded(
                  child: entries.isEmpty && _searchQuery.isNotEmpty
                      ? _buildNoResultsState()
                      : entries.isEmpty && vaultData.entries.isEmpty
                      ? _buildEmptyState(context)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    3, // Changed from 2 to 3 cards per row
                                childAspectRatio:
                                    0.85, // Adjusted for 3 columns
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            // Get subtitle
                            String? subtitle;
                            try {
                              final usernameField = entry.fields.firstWhere(
                                (f) =>
                                    f.label.toLowerCase().contains(
                                      'username',
                                    ) ||
                                    f.label.toLowerCase().contains('email'),
                              );
                              subtitle = usernameField.value;
                            } catch (_) {
                              subtitle = 'Secured Item';
                            }

                            return InkWell(
                              onTap: () => _showEntryDetails(context, entry),
                              onLongPress: () => _showEntryMenu(context, entry),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    8,
                                  ), // Reduced from 12 for 3 columns
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width:
                                            40, // Reduced from 48 for 3 columns
                                        height:
                                            40, // Reduced from 48 for 3 columns
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0066CC,
                                          ).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.shield_rounded,
                                          color: Color(0xFF0066CC),
                                          size:
                                              20, // Reduced from 24 for 3 columns
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 6,
                                      ), // Reduced from 8
                                      Text(
                                        entry.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              12, // Reduced from 14 for 3 columns
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize:
                                              10, // Reduced from 11 for 3 columns
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Your vault is empty',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showAddEntryDialog(context),
            child: const Text('Add your first secret'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No matches found for "$_searchQuery"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    Navigator.push(context, SlideUpPageRoute(child: const AddEntryScreen()));
  }

  void _showEntryDetails(BuildContext context, VaultEntry entry) {
    Navigator.push(
      context,
      FadePageRoute(child: EntryDetailScreen(entryId: entry.id)),
    );
  }

  void _showEntryMenu(BuildContext context, VaultEntry entry) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircularAction(
                    context: context,
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    color: Colors.blue,
                    onTap: () async {
                      final authenticated = await SecurityUtils.authenticate(
                        context,
                      );

                      if (authenticated && context.mounted) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          SlideUpPageRoute(
                            child: AddEntryScreen(entryToEdit: entry),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Authentication required to edit entries',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildCircularAction(
                    context: context,
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete(context, entry);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
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
        content: Text(
          'Are you sure you want to remove "${entry.title}"? This action requires biometric or master password verification.',
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
        final vaultProvider = Provider.of<VaultProvider>(
          context,
          listen: false,
        );
        await vaultProvider.deleteEntry(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('"${entry.title}" deleted')));
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Deletion aborted.'),
          ),
        );
      }
    }
  }
}
