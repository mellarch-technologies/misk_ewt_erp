// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  User? user;
  bool busy = false;

  AuthProvider() {
    _service.authStateChanges.listen((u) {
      user = u;
      notifyListeners();
    });
  }

  Future<void> login(String email, String pass) async {
    busy = true;
    notifyListeners();
    await _service.signIn(email, pass);
    busy = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.signOut();
  }

  Future<void> forgotPassword(String email) async {
    await _service.resetPassword(email);
  }
}