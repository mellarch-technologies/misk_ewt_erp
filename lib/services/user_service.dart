// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _col = FirebaseFirestore.instance.collection('users');

  Stream<List<UserModel>> streamUsers() => _col
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs
      .map((doc) => UserModel.fromJson(doc.data(), doc.id))
      .toList());

  Future addUser(UserModel u) => _col.add({
    ...u.toJson(),
    'CreatedAt': FieldValue.serverTimestamp(),
  });

  Future updateUser(UserModel u) => _col.doc(u.uid).update(u.toJson());

  Future deleteUser(String uid) => _col.doc(uid).delete();
}
