// File: lib/public_firebase_options.dart
// Temporary bridge for the Public app until you generate a dedicated
// public_firebase_options.dart via FlutterFire for com.miskewt.misk.
// This forwards to the existing DefaultFirebaseOptions so builds run.
// Replace this file with the generated one when ready.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'firebase_options.dart' show DefaultFirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class PublicFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Forward to DefaultFirebaseOptions for now. Replace with generated values later.
    if (kIsWeb) return DefaultFirebaseOptions.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return DefaultFirebaseOptions.android;
      case TargetPlatform.iOS:
        return DefaultFirebaseOptions.ios;
      case TargetPlatform.macOS:
        return DefaultFirebaseOptions.macos;
      case TargetPlatform.windows:
        return DefaultFirebaseOptions.windows;
      case TargetPlatform.linux:
        throw UnsupportedError('PublicFirebaseOptions not configured for linux.');
      default:
        throw UnsupportedError('PublicFirebaseOptions are not supported for this platform.');
    }
  }
}

