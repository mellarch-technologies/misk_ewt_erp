// lib/providers/permission_provider.dart
import 'package:flutter/material.dart';
import '../models/role_model.dart';
import '../models/user_model.dart';

class PermissionProvider extends ChangeNotifier {
  Role? _userRole;
  bool _isLoading = false;
  bool _isSuperAdmin = false;

  bool get isLoading => _isLoading;
  // Corrected: If it's a Super Admin, always display "Super Admin"
  String get roleName => _isSuperAdmin ? 'Super Admin' : (_userRole?.name ?? 'Guest');

  Future<void> loadUserPermissions(UserModel? user) async {
    if (user == null) {
      clearPermissions();
      return;
    }

    _isLoading = true;
    _isSuperAdmin = user.isSuperAdmin;
    notifyListeners();

    // If the user has no role reference, or if they are a super admin (role name is overridden anyway),
    // we don't strictly need to fetch the role document if it's causing issues.
    // However, for consistency and future expansion, we still try to fetch it.
    if (user.roleId == null) {
      _userRole = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final roleDoc = await user.roleId!.get();

      if (roleDoc.exists) {
        _userRole = Role.fromFirestore(roleDoc.data()! as Map<String, dynamic>, roleDoc.id);
      } else {
        print("Warning: Role document with path '${user.roleId!.path}' not found.");
        _userRole = null;
      }
    } catch (e) {
      print("Error loading user permissions from reference: $e");
      _userRole = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
