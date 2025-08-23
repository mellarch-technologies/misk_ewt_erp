// lib/providers/permission_provider.dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:meta/meta.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role_model.dart';
import '../models/user_model.dart';

class PermissionProvider extends ChangeNotifier {
  Role? _userRole;
  bool _isLoading = false;
  bool _isSuperAdmin = false;

  bool get isLoading => _isLoading;
  // Corrected: If it's a Super Admin, always display "Super Admin"
  String get roleName => _isSuperAdmin ? 'Super Admin' : (_userRole?.name ?? 'Guest');
  Role? get userRole => _userRole;
  bool get isSuperAdmin => _isSuperAdmin;

  Future<void> loadUserPermissions(UserModel? user) async {
    final logFile = await _getDebugLogFile();
    Future<void> logToFile(String message) async {
      await logFile.writeAsString('$message\n', mode: FileMode.append);
      print(message); // Also print to console for immediate visibility
    }
    await logToFile('DEBUG: loadUserPermissions called with user:');
    await logToFile('DEBUG: user = ${user != null ? user.toString() : 'null'}');
    if (user == null) {
      clearPermissions();
      await logToFile('DEBUG: user is null, permissions cleared.');
      return;
    }
    _isLoading = true;
    _isSuperAdmin = user.isSuperAdmin;
    notifyListeners();
    if (user.roleId == null) {
      await logToFile('DEBUG: user.roleId is null, cannot load role.');
      _userRole = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      await logToFile('DEBUG: Fetching role document from Firestore: ${user.roleId!.path}');
      final roleDoc = await user.roleId!.get();
      if (roleDoc.exists) {
        await logToFile('DEBUG: Role document found: ${roleDoc.id}');
        await logToFile('DEBUG: Role data: ${roleDoc.data()}');
        _userRole = Role.fromFirestore(roleDoc.data()! as Map<String, dynamic>, roleDoc.id);
      } else {
        await logToFile("Warning: Role document with path '${user.roleId!.path}' not found.");
        _userRole = null;
      }
    } catch (e) {
      await logToFile("Error loading user permissions from reference: $e");
      _userRole = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New: Load permissions by user email (query Firestore users once)
  Future<void> loadForEmail(String? email) async {
    if (email == null || email.isEmpty) {
      clearPermissions();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final qs = await FirebaseFirestore.instance.collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (qs.docs.isEmpty) {
        clearPermissions();
        return;
      }
      final doc = qs.docs.first;
      final user = UserModel.fromJson(doc.data(), doc.id);
      await loadUserPermissions(user);
    } catch (e) {
      // On failure, keep safe default (no permissions)
      _userRole = null;
      _isSuperAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void debugSetRole(Role? role, {bool isSuperAdmin = false}) {
    _userRole = role;
    _isSuperAdmin = isSuperAdmin;
    notifyListeners();
  }

  Future<File> _getDebugLogFile() async {
    // Use path_provider to get the app directory
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/PermissionProvider_debug_log.txt');
  }

  bool can(String permissionKey) {
    if (_isSuperAdmin) {
      return true; // Master override for Super Admins
    }
    return _userRole?.permissions[permissionKey] ?? false;
  }

  void clearPermissions() {
    _userRole = null;
    _isSuperAdmin = false;
    notifyListeners();
  }
}
