// lib/models/role_model.dart

class Role {
  final String id;
  final String name;
  final Map<String, bool> permissions;

  Role({
    required this.id,
    required this.name,
    required this.permissions,
  });

  factory Role.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Role(
      id: documentId,
      name: data['name'] ?? 'Unknown Role',
      permissions: Map<String, bool>.from(data['permissions'] ?? {}),
    );
  }
}
