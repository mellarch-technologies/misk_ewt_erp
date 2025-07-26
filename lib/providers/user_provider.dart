// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final _service = UserService();
  List<UserModel> _all = [];
  bool _busy = false;
  String _filter = '';

  List<UserModel> get users => _filter.isEmpty
      ? _all
      : _all
      .where((u) =>
  u.name.toLowerCase().contains(_filter) ||
      u.email.toLowerCase().contains(_filter) ||
      u.role.name.toLowerCase().contains(_filter))
      .toList();
  bool get isBusy => _busy;

  void setFilter(String f) {
    _filter = f.toLowerCase();
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    _busy = true;
    notifyListeners();
    _service.streamUsers().listen((data) {
      _all = data;
      _busy = false;
      notifyListeners();
    });
  }

  Future<void> saveUser(UserModel u) async {
    _busy = true;
    notifyListeners();
    if (u.uid.isEmpty) {
      await _service.addUser(u);
    } else {
      await _service.updateUser(u);
    }
    _busy = false;
    notifyListeners();
  }

  Future<void> removeUser(String uid) async {
    await _service.deleteUser(uid);
    _all.removeWhere((u) => u.uid == uid);
    notifyListeners();
  }
}