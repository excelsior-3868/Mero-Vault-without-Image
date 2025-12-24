import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vault_entry.dart';
import '../../providers/vault_provider.dart';

class AddEntryScreen extends StatefulWidget {
  final VaultEntry? entryToEdit;
  const AddEntryScreen({super.key, this.entryToEdit});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _FieldController {
  final String id = UniqueKey().toString(); // Stable ID for keys
  final TextEditingController label;
  final TextEditingController value;
  bool isObscured;

  _FieldController({
    String labelText = '', 
    String valueText = '', 
    this.isObscured = false
  }) : label = TextEditingController(text: labelText),
       value = TextEditingController(text: valueText);
  
  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<_FieldController> _fields = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      final e = widget.entryToEdit!;
      _titleController.text = e.title;
      // Load existing fields
      for (var f in e.fields) {
        _fields.add(_FieldController(
          labelText: f.label,
          valueText: f.value,
          isObscured: f.isObscured,
        ));
      }
    } else {
      // Default fields for new entry
      _fields.add(_FieldController(labelText: 'Username'));
      _fields.add(_FieldController(labelText: 'Password', isObscured: true));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var f in _fields) f.dispose();
    super.dispose();
  }

  void _addField() {
    setState(() {
      _fields.add(_FieldController());
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields[index].dispose();
      _fields.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<VaultProvider>(context, listen: false);

      // Convert controllers to VaultField list
      final vaultFields = _fields.map((c) => VaultField(
        label: c.label.text,
        value: c.value.text,
        isObscured: c.isObscured,
      )).toList();

      if (widget.entryToEdit != null) {
        // Update
        final updatedEntry = VaultEntry(
          id: widget.entryToEdit!.id,
          title: _titleController.text,
          fields: vaultFields,
          createdAt: widget.entryToEdit!.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
        await provider.updateEntry(updatedEntry);
      } else {
        // Create
        final entry = VaultEntry.create(
          title: _titleController.text,
          fields: vaultFields,
        );
        await provider.addEntry(entry);
      }

      if (mounted) {
        Navigator.pop(context); // Go back
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(widget.entryToEdit != null ? 'Entry updated' : 'Entry saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryToEdit != null ? 'Edit Entry' : 'Add Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Entry Title',
                  hintText: 'e.g. Gmail, Netflix, Bank',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Fields', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   TextButton.icon(
                     onPressed: _addField,
                     icon: const Icon(Icons.add),
                     label: const Text('Add Field'),
                   ),
                ],
              ),
              const SizedBox(height: 8),
              
              ..._fields.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Card(
                  key: ValueKey(controller.id), // Important for state preservation
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller.label,
                                decoration: const InputDecoration(
                                  labelText: 'Field Name (e.g. Username, PIN)',
                                  isDense: true,
                                  border: UnderlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () => _removeField(index),
                              tooltip: 'Remove Field',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller.value,
                                obscureText: controller.isObscured, 
                                decoration: InputDecoration(
                                  labelText: controller.isObscured ? 'Secret Value' : 'Value',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: IconButton(
                                     icon: Icon(controller.isObscured ? Icons.visibility : Icons.visibility_off),
                                     onPressed: () {
                                        setState(() {
                                          controller.isObscured = !controller.isObscured;
                                        });
                                     },
                                     tooltip: controller.isObscured ? 'Show value' : 'Hide value',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Option Checkbox
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: controller.isObscured,
                                onChanged: (val) {
                                  setState(() {
                                    controller.isObscured = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Treat as Password (Hidden)'),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),

              if (_fields.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No fields added yet. TAP "Add Field" to start.', style: TextStyle(color: Colors.grey))),
                ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Entry'),
              ),
              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
    );
  }
}
