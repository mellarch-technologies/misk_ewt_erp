// lib/providers/app_auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// The correct, standardized name for our custom provider.
class AppAuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AppAuthProvider() {
    _service.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.signIn(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow; // Rethrow the error so the UI can display it
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    // We will add permission clearing logic here later
    await _service.signOut();
  }
}
