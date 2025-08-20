// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthFailure implements Exception {
  final String code;
  final String message;
  AuthFailure(this.code, this.message);

  @override
  String toString() => 'AuthFailure($code): $message';
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthFailure('unknown', 'Unexpected error. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthFailure('unknown', 'Unexpected error. Please try again.');
    }
  }

  AuthFailure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthFailure(e.code, 'The email address is invalid.');
      case 'user-disabled':
        return AuthFailure(e.code, 'This user account has been disabled.');
      case 'user-not-found':
        return AuthFailure(e.code, 'No user found with this email.');
      case 'wrong-password':
        return AuthFailure(e.code, 'Incorrect password.');
      case 'too-many-requests':
        return AuthFailure(e.code, 'Too many attempts. Please try again later.');
      case 'network-request-failed':
        return AuthFailure(e.code, 'Network error. Please check your connection.');
      case 'email-already-in-use':
        return AuthFailure(e.code, 'Email is already in use.');
      case 'weak-password':
        return AuthFailure(e.code, 'Password is too weak.');
      default:
        return AuthFailure(e.code, e.message ?? 'Authentication error.');
    }
  }
}
