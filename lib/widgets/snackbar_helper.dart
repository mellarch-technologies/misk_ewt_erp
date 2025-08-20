// lib/widgets/snackbar_helper.dart
import 'package:flutter/material.dart';

class SnackbarHelper {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, background: Colors.green);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, background: Colors.red);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, background: Colors.black87);
  }

  static void _show(BuildContext context, String message, {Color? background}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }
}

