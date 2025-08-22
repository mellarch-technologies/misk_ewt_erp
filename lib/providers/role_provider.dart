// lib/providers/role_provider.dart
import 'package:flutter/material.dart';
import '../models/role_model.dart';
import '../services/role_service.dart';

class RoleProvider extends ChangeNotifier {
  final RoleService _service = RoleService();
  List<Role> _roles = [];
  bool _isLoading = false;
  String? _error;

  List<Role> get roles => _roles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RoleProvider() {
    fetchRoles();
    _service.streamRoles().listen((roles) {
      _roles = roles;
      _error = null; // clear any previous load error on live updates
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  Future<void> fetchRoles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _roles = await _service.fetchRoles();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> addRole(Role role, {required String currentUserId}) async {
    try {
      await _service.addRole(role, currentUserId: currentUserId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateRole(Role role, {required String currentUserId}) async {
    try {
      await _service.updateRole(role, currentUserId: currentUserId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      await _service.deleteRole(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
