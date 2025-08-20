// lib/providers/role_provider.dart
import 'package:flutter/material.dart';
import '../models/role_model.dart';
import '../services/role_service.dart';

class RoleProvider extends ChangeNotifier {
  final RoleService _service = RoleService();
  List<Role> _roles = [];
  bool _isLoading = false;

  List<Role> get roles => _roles;
  bool get isLoading => _isLoading;

  RoleProvider() {
    fetchRoles();
    _service.streamRoles().listen((roles) {
      _roles = roles;
      notifyListeners();
    });
  }

  Future<void> fetchRoles() async {
    _isLoading = true;
    notifyListeners();
    _roles = await _service.fetchRoles();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRole(Role role, {required String currentUserId}) async {
    await _service.addRole(role, currentUserId: currentUserId);
  }

  Future<void> updateRole(Role role, {required String currentUserId}) async {
    await _service.updateRole(role, currentUserId: currentUserId);
  }

  Future<void> deleteRole(String id) async {
    await _service.deleteRole(id);
  }
}
