import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service = UserService();

  List<UserModel> _all = [];
  String _filter = '';
  bool _busy = true;
  String? _errorMessage;

  // Getters - keeping both APIs for compatibility
  List<UserModel> get users => _filter.isEmpty
      ? _all
      : _all.where((u) =>
  u.name.toLowerCase().contains(_filter) ||
      u.email.toLowerCase().contains(_filter) ||
      (u.phone ?? '').toLowerCase().contains(_filter) ||
      (u.status ?? '').toLowerCase().contains(_filter)).toList();

  bool get isBusy => _busy;
  bool get isLoading => _busy; // Alias for compatibility
  bool get isLoadingMore => false; // Simple implementation
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers({bool refresh = false}) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _all = await _service.getUsersOnce();
    } catch (e) {
      _errorMessage = e.toString();
      print("Error fetching users: $e");
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
    notifyListeners();
  }

  UserModel? getCurrentUserByEmail(String? email) {
    if (email == null) return null;
    return _all.firstWhereOrNull((u) => u.email == email);
  }

  Future<void> saveUser(UserModel user) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (user.uid.isEmpty) {
        await _service.addUser(user);
      } else {
        await _service.updateUser(user);
      }
      await fetchUsers(); // Always re-fetch to update list
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> removeUser(String uid) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteUser(uid);
      await fetchUsers(); // Always re-fetch to update list
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
