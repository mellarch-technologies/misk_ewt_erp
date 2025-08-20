// lib/providers/app_auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/audit_service.dart';
import 'dart:async';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _service;
  final AuditService _audit;

  AppAuthProvider({AuthService? service, AuditService? audit})
      : _service = service ?? AuthService(),
        _audit = audit ?? AuditService() {
    _service.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? _user;
  bool _isLoading = false;

  // Throttling/lockout state
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _lockoutTicker;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  Duration? get lockoutRemaining => isLockedOut ? _lockoutUntil!.difference(DateTime.now()) : null;

  void _startLockout() {
    _lockoutUntil = DateTime.now().add(_lockoutDuration);
    _lockoutTicker?.cancel();
    // Tick every second so UI can update remaining time if needed
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isLockedOut) {
        t.cancel();
        _lockoutTicker = null;
        _failedAttempts = 0; // reset after lockout ends
        _lockoutUntil = null;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void _resetFailures() {
    _failedAttempts = 0;
    _lockoutUntil = null;
    _lockoutTicker?.cancel();
    _lockoutTicker = null;
  }

  Future<void> login(String email, String password) async {
    if (isLockedOut) {
      final secs = lockoutRemaining?.inSeconds ?? _lockoutDuration.inSeconds;
      throw AuthFailure('too-many-requests', 'Too many failed attempts. Try again in ${secs}s.');
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _service.signIn(email, password);
      _resetFailures();
      // Audit success
      await _audit.logAuthEvent(
        type: 'login',
        email: email,
        uid: FirebaseAuth.instance.currentUser?.uid,
        success: true,
      );
    } on AuthFailure catch (e) {
      // Increment failures for common auth errors only
      if (e.code == 'invalid-email' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        _failedAttempts += 1;
        if (_failedAttempts >= _maxFailedAttempts) {
          _startLockout();
        } else {
          notifyListeners();
        }
      }
      // Audit failure
      await _audit.logAuthEvent(
        type: 'login',
        email: email,
        success: false,
        errorCode: e.code,
      );
      rethrow;
    } catch (e) {
      // Audit unknown failure
      await _audit.logAuthEvent(
        type: 'login',
        email: email,
        success: false,
        errorCode: 'unknown',
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final uid = _user?.uid;
    await _service.signOut();
    // Audit logout
    await _audit.logAuthEvent(type: 'logout', uid: uid, success: true);
    // Optionally: clear other providers' state here
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _service.sendPasswordResetEmail(email);
      await _audit.logAuthEvent(type: 'password_reset_request', email: email, success: true);
    } on AuthFailure catch (e) {
      await _audit.logAuthEvent(type: 'password_reset_request', email: email, success: false, errorCode: e.code);
      rethrow;
    } catch (e) {
      await _audit.logAuthEvent(type: 'password_reset_request', email: email, success: false, errorCode: 'unknown');
      rethrow; // AuthFailure or unknown
    }
  }
}
