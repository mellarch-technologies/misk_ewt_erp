// lib/models/role_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Role {
  final String id;
  final String name;
  final Map<String, bool> permissions;
  final bool protected;
  final String? description;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Role({
    required this.id,
    required this.name,
    required this.permissions,
    this.protected = false,
    this.description,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Role.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Role(
      id: documentId,
      name: data['name'] ?? 'Unknown Role',
      permissions: Map<String, bool>.from(data['permissions'] ?? {}),
      protected: data['protected'] ?? false,
      description: data['description'],
      createdBy: data['createdBy'],
      updatedBy: data['updatedBy'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'permissions': permissions,
        'protected': protected,
        'description': description,
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };
}
