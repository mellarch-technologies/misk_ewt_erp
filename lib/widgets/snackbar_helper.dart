// lib/widgets/snackbar_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SnackbarHelper {
  static bool enableSounds = false;

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, background: Colors.green);
    if (enableSounds) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    }
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, background: Colors.red);
    if (enableSounds) {
      HapticFeedback.heavyImpact();
    }
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, background: Colors.black87);
    if (enableSounds) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
  }

  static void _show(BuildContext context, String message, {Color? background}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }
}
