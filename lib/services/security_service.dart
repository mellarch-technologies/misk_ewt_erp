// lib/services/security_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_lock_provider.dart';

class SecurityService {
  const SecurityService();

  Future<bool> ensureReauthenticated(BuildContext context, {String? reason}) async {
    // Prefer App Lock PIN if enabled
    final lock = context.read<AppLockProvider>();
    if (lock.enabled && lock.hasPin) {
      final ok = await _promptForPin(context, reason: reason);
      return ok;
    }
    // Fallback to password re-auth
    final ok = await _promptForPassword(context, reason: reason);
    return ok;
  }

  Future<bool> _promptForPin(BuildContext context, {String? reason}) async {
    final lock = context.read<AppLockProvider>();
    final controller = TextEditingController();
    String? error;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reason != null) Text(reason),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Enter PIN',
                errorText: error,
              ),
              onSubmitted: (_) => Navigator.of(ctx).pop(lock.verifyPin(controller.text.trim())),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final ok = lock.verifyPin(controller.text.trim());
              if (!ok) {
                error = 'Invalid PIN';
                (ctx as Element).markNeedsBuild();
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<bool> _promptForPassword(BuildContext context, {String? reason}) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return false;

    final controller = TextEditingController();
    String? errorText;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Confirm Identity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reason != null) Text(reason),
              const SizedBox(height: 8),
              Text('Email: $email'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: errorText,
                ),
                onSubmitted: (_) async {
                  final success = await _reauth(email, controller.text.trim());
                  if (!success) {
                    setState(() => errorText = 'Incorrect password');
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final success = await _reauth(email, controller.text.trim());
                if (!success) {
                  setState(() => errorText = 'Incorrect password');
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  Future<bool> _reauth(String email, String password) async {
    try {
      final cred = EmailAuthProvider.credential(email: email, password: password);
      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(cred);
      return true;
    } catch (_) {
      return false;
    }
  }
}

