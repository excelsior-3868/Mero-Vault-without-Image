import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vault_entry.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/branded_app_bar.dart';
import '../../widgets/toast_notification.dart';

class AddEntryScreen extends StatefulWidget {
  final VaultEntry? entryToEdit;
  const AddEntryScreen({super.key, this.entryToEdit});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _FieldController {
  final String id = UniqueKey().toString();
  final TextEditingController label;
  final TextEditingController value;
  String selectedType;
  bool isObscured;
  bool isPasswordVisible = false;

  _FieldController({
    String labelText = 'Username',
    String valueText = '',
    this.selectedType = 'Username',
    this.isObscured = false,
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

  final List<String> _fieldTypes = [
    'Username',
    'Password',
    'Pin Code',
    'Transaction Password',
    'URL',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      final e = widget.entryToEdit!;
      _titleController.text = e.title;
      for (var f in e.fields) {
        String type = _fieldTypes.contains(f.label) ? f.label : 'Custom';
        _fields.add(
          _FieldController(
            labelText: f.label,
            valueText: f.value,
            selectedType: type,
            isObscured: f.isObscured,
          ),
        );
      }
    } else {
      _fields.add(
        _FieldController(selectedType: 'Username', labelText: 'Username'),
      );
      _fields.add(
        _FieldController(
          selectedType: 'Password',
          labelText: 'Password',
          isObscured: true,
        ),
      );
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
      _fields.add(
        _FieldController(selectedType: 'Username', labelText: 'Username'),
      );
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields[index].dispose();
      _fields.removeAt(index);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<VaultProvider>(context, listen: false);

      final vaultFields = _fields
          .map(
            (c) => VaultField(
              label: c.selectedType == 'Custom' ? c.label.text : c.selectedType,
              value: c.value.text,
              isObscured: c.isObscured,
            ),
          )
          .toList();

      final bool success;
      if (widget.entryToEdit != null) {
        final updatedEntry = VaultEntry(
          id: widget.entryToEdit!.id,
          title: _titleController.text,
          fields: vaultFields,
          createdAt: widget.entryToEdit!.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
        success = await provider.updateEntry(updatedEntry);
      } else {
        final entry = VaultEntry.create(
          title: _titleController.text,
          fields: vaultFields,
        );
        success = await provider.addEntry(entry);
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ToastNotification.show(
            context,
            widget.entryToEdit != null
                ? 'Entry updated successfully'
                : 'Entry saved to vault',
          );
        } else {
          ToastNotification.show(
            context,
            'Failed to save entry. Please check your internet connection and try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Error saving: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFD32F2F);
    const primaryBlue = Color(0xFF0066CC);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const BrandedAppBar(title: 'MERO VAULT', showLogo: true),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  ),
                const SizedBox(height: 4),
                // Title Section
                Text(
                  'BASIC INFORMATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[400],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    prefixIcon: const Icon(
                      Icons.shield_rounded,
                      color: primaryRed,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryRed, width: 2),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Title is required' : null,
                ),

                const SizedBox(height: 12),

                // Dynamic Fields Header
                Text(
                  'SECURE FIELDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[400],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),

                ..._fields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Container(
                    key: ValueKey(controller.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: controller.selectedType,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                ),
                                items: _fieldTypes
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    controller.selectedType = val!;
                                    if (val == 'Password' ||
                                        val == 'Pin Code' ||
                                        val == 'Transaction Password') {
                                      controller.isObscured = true;
                                      controller.isPasswordVisible = false;
                                    } else if (val == 'Custom') {
                                      controller.isObscured = false;
                                      controller.isPasswordVisible = true;
                                      controller.label.clear();
                                      controller.value.clear();
                                    } else {
                                      controller.isObscured = false;
                                      controller.isPasswordVisible = true;
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Field Type',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: primaryRed,
                                size: 18,
                              ),
                              onPressed: () => _removeField(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Remove Field',
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        if (controller.selectedType == 'Custom') ...[
                          TextFormField(
                            controller: controller.label,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Custom Label',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextFormField(
                          controller: controller.value,
                          obscureText:
                              (controller.selectedType == 'Password' ||
                                  controller.selectedType == 'Pin Code' ||
                                  controller.selectedType ==
                                      'Transaction Password')
                              ? !controller.isPasswordVisible
                              : false,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              _getIconForType(controller.selectedType),
                              size: 18,
                              color: primaryBlue,
                            ),
                            suffixIcon:
                                (controller.selectedType == 'Password' ||
                                    controller.selectedType == 'Pin Code' ||
                                    controller.selectedType ==
                                        'Transaction Password')
                                ? IconButton(
                                    icon: Icon(
                                      controller.isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        controller.isPasswordVisible =
                                            !controller.isPasswordVisible;
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (controller.selectedType == 'Password' ||
                            controller.selectedType == 'Pin Code' ||
                            controller.selectedType == 'Transaction Password')
                          InkWell(
                            onTap: () {
                              setState(() {
                                controller.isObscured = !controller.isObscured;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: controller.isObscured
                                    ? primaryRed.withOpacity(0.05)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: controller.isObscured
                                      ? primaryRed.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: controller.isObscured,
                                      activeColor: primaryRed,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          controller.isObscured = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TREAT AS SENSITIVE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: controller.isObscured
                                                ? primaryRed
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          'Requires Biometric/Master Password to view',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                if (_fields.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_moderator_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No secure fields added yet.',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _addField,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('ADD ANOTHER FIELD'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryBlue,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryRed.withOpacity(0.6),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.lock_rounded, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        _isLoading
                            ? 'ENCRYPTING...'
                            : 'SAVE TO ENCRYPTED VAULT',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Username':
        return Icons.person_outline_rounded;
      case 'Password':
        return Icons.key_outlined;
      case 'Pin Code':
        return Icons.password_rounded;
      case 'Transaction Password':
        return Icons.lock_clock_rounded;
      case 'URL':
        return Icons.link_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
