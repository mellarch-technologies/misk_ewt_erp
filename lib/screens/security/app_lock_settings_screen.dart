// lib/screens/security/app_lock_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_lock_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/security_service.dart';
import '../../widgets/snackbar_helper.dart';
import 'package:local_auth/local_auth.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  bool _saving = false;
  final _localAuth = LocalAuthentication();

  Future<void> _setOrChangePin(BuildContext context) async {
    // Require re-authentication for changing PIN
    final ok = await const SecurityService().ensureReauthenticated(
      context,
      reason: 'Confirm your identity to ${context.read<AppLockProvider>().hasPin ? 'change' : 'set'} PIN.',
    );
    if (!ok) {
      if (mounted) SnackbarHelper.showInfo(context, 'Action cancelled');
      return;
    }

    final lock = context.read<AppLockProvider>();
    final pin1 = await _promptForPin(context, title: lock.hasPin ? 'Enter New PIN' : 'Set PIN');
    if (!mounted || pin1 == null) return;
    final pin2 = await _promptForPin(context, title: 'Confirm PIN');
    if (!mounted || pin2 == null) return;
    if (pin1 != pin2) {
      SnackbarHelper.showError(context, 'PINs do not match');
      return;
    }
    setState(() => _saving = true);
    await lock.setPin(pin1);
    if (!mounted) return;
    setState(() => _saving = false);
    SnackbarHelper.showSuccess(context, 'PIN updated successfully');
  }

  Future<String?> _promptForPin(BuildContext context, {required String title}) async {
    final controller = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter 4-6 digit PIN',
                  errorText: error,
                ),
                onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.length < 4 || value.length > 6 || int.tryParse(value) == null) {
                  setState(() => error = 'PIN must be 4–6 digits');
                  return;
                }
                Navigator.of(ctx).pop(value);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & App Lock'),
        backgroundColor: MiskTheme.miskDarkGreen,
        foregroundColor: MiskTheme.miskWhite,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: lock.enabled,
            onChanged: (v) async {
              final ok = await const SecurityService().ensureReauthenticated(
                context,
                reason: v ? 'Confirm to enable App Lock.' : 'Confirm to disable App Lock.',
              );
              if (!ok) {
                if (mounted) SnackbarHelper.showInfo(context, 'Action cancelled');
                return;
              }
              await context.read<AppLockProvider>().setEnabled(v);
              if (!mounted) return;
              SnackbarHelper.showSuccess(context, v ? 'App Lock enabled' : 'App Lock disabled');
            },
            title: const Text('Enable App Lock'),
            subtitle: const Text('Protect the app with a PIN (and biometrics if available).'),
          ),
          if (lock.enabled) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.pin),
              title: Text(lock.hasPin ? 'Change PIN' : 'Set PIN'),
              subtitle: const Text('Use a 4–6 digit PIN to unlock the app'),
              trailing: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _saving ? null : () => _setOrChangePin(context),
            ),
            SwitchListTile(
              value: lock.biometricEnabled,
              onChanged: (v) async {
                final ok = await const SecurityService().ensureReauthenticated(
                  context,
                  reason: v ? 'Confirm to enable biometrics.' : 'Confirm to disable biometrics.',
                );
                if (!ok) {
                  if (mounted) SnackbarHelper.showInfo(context, 'Action cancelled');
                  return;
                }
                if (v) {
                  bool supported = false;
                  try {
                    supported = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
                  } catch (_) {
                    supported = false;
                  }
                  if (!supported) {
                    if (!mounted) return;
                    SnackbarHelper.showError(context, 'Biometric authentication not supported on this device');
                    return; // do not enable
                  }
                }
                await context.read<AppLockProvider>().setBiometricEnabled(v);
                if (!mounted) return;
                SnackbarHelper.showSuccess(context, v ? 'Biometrics enabled' : 'Biometrics disabled');
              },
              title: const Text('Enable Biometrics'),
              subtitle: const Text('Fingerprint/Face unlock (when supported)'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Idle Timeout'),
              subtitle: Text('${lock.idleTimeout.inMinutes} minutes'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final ok = await const SecurityService().ensureReauthenticated(
                  context,
                  reason: 'Confirm your identity to change idle timeout.',
                );
                if (!ok) {
                  if (mounted) SnackbarHelper.showInfo(context, 'Action cancelled');
                  return;
                }
                final selected = await _pickTimeout(context, lock.idleTimeout);
                if (selected != null) {
                  await lock.setIdleTimeout(selected);
                  if (!mounted) return;
                  SnackbarHelper.showSuccess(context, 'Idle timeout set to ${selected.inMinutes} minutes');
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<Duration?> _pickTimeout(BuildContext context, Duration current) async {
    final options = <Duration>[
      const Duration(minutes: 5),
      const Duration(minutes: 10),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
    ];
    return showModalBottomSheet<Duration>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Select Idle Timeout')),
          for (final d in options)
            RadioListTile<Duration>(
              value: d,
              groupValue: current,
              title: Text('${d.inMinutes} minutes'),
              onChanged: (val) => Navigator.pop(ctx, val),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
