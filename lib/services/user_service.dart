// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _col = FirebaseFirestore.instance.collection('users');

  Stream<List<UserModel>> streamUsers() => _col
      .orderBy('Name')
      .snapshots()
      .map((snap) => snap.docs
      .map((doc) => UserModel.fromJson(doc.data(), doc.id))
      .toList());

  Future<void> addUser(UserModel u) => _col.add(u.toJson());

  Future<void> updateUser(UserModel u) => _col.doc(u.uid).update(u.toJson());

  Future<void> deleteUser(String uid) => _col.doc(uid).delete();
}
