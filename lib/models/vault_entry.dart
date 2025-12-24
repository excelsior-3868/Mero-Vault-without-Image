import 'package:uuid/uuid.dart';

class VaultField {
  String label;
  String value;
  bool isObscured;
  // We can add 'type' later if needed (e.g. 'url', 'otp')

  VaultField({
    required this.label,
    required this.value,
    this.isObscured = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'is_obscured': isObscured,
    };
  }

  factory VaultField.fromJson(Map<String, dynamic> json) {
    return VaultField(
      label: json['label'] as String? ?? 'Field',
      value: json['value'] as String? ?? '',
      isObscured: json['is_obscured'] as bool? ?? false,
    );
  }
}

class VaultEntry {
  final String id;
  String title;
  List<VaultField> fields; // Dynamic fields
  final DateTime createdAt;
  DateTime updatedAt;

  VaultEntry({
    required this.id,
    required this.title,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VaultEntry.create({
    required String title,
    List<VaultField>? fields,
  }) {
    final now = DateTime.now().toUtc();
    return VaultEntry(
      id: const Uuid().v4(),
      title: title,
      fields: fields ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory VaultEntry.fromJson(Map<String, dynamic> json) {
    var fieldsList = <VaultField>[];

    // Handle new structure
    if (json['fields'] != null) {
      json['fields'].forEach((v) {
        fieldsList.add(VaultField.fromJson(v));
      });
    } else {
      // Backward compatibility for old structure
      if (json['username'] != null) {
        fieldsList.add(VaultField(label: 'Username', value: json['username']));
      }
      if (json['password'] != null) {
        fieldsList.add(VaultField(label: 'Password', value: json['password'], isObscured: true));
      }
      if (json['url'] != null && (json['url'] as String).isNotEmpty) {
        fieldsList.add(VaultField(label: 'URL', value: json['url']));
      }
      if (json['notes'] != null && (json['notes'] as String).isNotEmpty) {
        fieldsList.add(VaultField(label: 'Notes', value: json['notes']));
      }
    }

    return VaultEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      fields: fieldsList,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'fields': fields.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VaultData {
  final String version;
  final DateTime lastUpdated;
  final List<VaultEntry> entries;

  VaultData({
    required this.version,
    required this.lastUpdated,
    required this.entries,
  });

  factory VaultData.fromJson(Map<String, dynamic> json) {
    final meta = json['vault_meta'] as Map<String, dynamic>? ?? {};
    final entriesList = json['entries'] as List<dynamic>? ?? [];
    
    return VaultData(
      version: meta['version'] as String? ?? '1.2', // Bump version for dynamic fields
      lastUpdated: meta['last_updated'] != null 
          ? DateTime.parse(meta['last_updated'] as String) 
          : DateTime.now().toUtc(),
      entries: entriesList.map((e) => VaultEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vault_meta': {
        'version': version,
        'encryption': 'AES-256-GCM',
        'last_updated': lastUpdated.toIso8601String(),
      },
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
}
