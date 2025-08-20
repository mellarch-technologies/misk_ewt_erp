// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  UserServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'UserServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

class UserService {
  final _col = FirebaseFirestore.instance.collection('users');

  Future<List<UserModel>> getUsersOnce() async {
    try {
      final snap = await _col.orderBy('name').get();
      return snap.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw UserServiceException(
        'Failed to fetch users',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw UserServiceException(
        'Unexpected error while fetching users',
        originalError: e,
      );
    }
  }

  Stream<List<UserModel>> streamUsers() {
    return _col
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => UserModel.fromJson(doc.data(), doc.id))
        .toList())
        .handleError((error) {
      throw UserServiceException(
        'Error streaming users',
        code: error is FirebaseException ? error.code : null,
        originalError: error,
      );
    });
  }

  Future<void> addUser(UserModel u) async {
    try {
      if (u.email.isEmpty || u.name.isEmpty) {
        throw UserServiceException('Email and name are required');
      }

      final existing = await _col
          .where('email', isEqualTo: u.email)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw UserServiceException('User with this email already exists');
      }

      await _col.add({
        ...u.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on UserServiceException {
      rethrow;
    } catch (e) {
      throw UserServiceException('Failed to add user', originalError: e);
    }
  }

  Future<void> updateUser(UserModel u) async {
    try {
      if (u.uid.isEmpty) {
        throw UserServiceException('User ID is required for update');
      }

      await _col.doc(u.uid).update({
        ...u.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw UserServiceException(
        'Failed to update user',
        code: e is FirebaseException ? e.code : null,
        originalError: e,
      );
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      final doc = await _col.doc(uid).get();
      if (!doc.exists) {
        throw UserServiceException('User not found');
      }

      await _col.doc(uid).delete();
    } catch (e) {
      throw UserServiceException(
        'Failed to delete user',
        code: e is FirebaseException ? e.code : null,
        originalError: e,
      );
    }
  }
}
