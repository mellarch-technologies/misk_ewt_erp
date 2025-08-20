// lib/services/role_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role_model.dart';

class RoleService {
  final _col = FirebaseFirestore.instance.collection('roles');

  Stream<List<Role>> streamRoles() =>
      _col.snapshots().map((snap) => snap.docs.map((doc) => Role.fromFirestore(doc.data(), doc.id)).toList());

  Future<List<Role>> fetchRoles() async {
    final snap = await _col.get();
    return snap.docs.map((doc) => Role.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<void> addRole(Role role, {required String currentUserId}) async {
    final now = FieldValue.serverTimestamp();
    await _col.add({
      'name': role.name,
      'permissions': role.permissions,
      'protected': role.protected,
      'description': role.description,
      'createdBy': currentUserId,
      'updatedBy': currentUserId,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateRole(Role role, {required String currentUserId}) async {
    // Prevent update if protected
    final doc = await _col.doc(role.id).get();
    if (doc.exists && (doc.data()?['protected'] ?? false)) {
      throw Exception('Cannot update a protected role.');
    }
    await _col.doc(role.id).update({
      'name': role.name,
      'permissions': role.permissions,
      'description': role.description,
      'updatedBy': currentUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRole(String id) async {
    // Prevent delete if protected
    final doc = await _col.doc(id).get();
    if (doc.exists && (doc.data()?['protected'] ?? false)) {
      throw Exception('Cannot delete a protected role.');
    }
    await _col.doc(id).delete();
  }
}
