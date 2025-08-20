// services/auth_service.dart
// This class handles all authentication logic with Firebase.

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Provide more user-friendly error messages
      String message = 'An error occurred';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      throw Exception(message);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

// TODO: Add functions for registration, password reset, etc.
}