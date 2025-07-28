// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service = UserService();

  List<UserModel> _all = [];
  String _filter = '';
  bool _busy = true;

  List<UserModel> get users => _filter.isEmpty
      ? _all
      : _all.where((u) =>
  u.name.toLowerCase().contains(_filter) ||
      u.email.toLowerCase().contains(_filter) ||
      // Cannot filter by roleId on the client, this would require an extra read.
      // This is a trade-off for a better data structure.
      (u.phone ?? '').toLowerCase().contains(_filter) ||
      (u.status ?? '').toLowerCase().contains(_filter)
  ).toList();

  bool get isBusy => _busy;

  Future<void> fetchUsers() async {
    _busy = true;
    notifyListeners();
    _service.streamUsers().listen((data) {
      _all = data;
      _busy = false;
      notifyListeners();
    });
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> saveUser(UserModel user) async {
    if (user.uid.isEmpty) {
      await _service.addUser(user);
    } else {
      await _service.updateUser(user);
    }
  }

  Future<void> removeUser(String uid) async {
    await _service.deleteUser(uid);
  }

  UserModel? getCurrentUserByEmail(String? email) {
    if (email == null) return null;
    return _all.firstWhereOrNull((u) => u.email == email);
  }
}
