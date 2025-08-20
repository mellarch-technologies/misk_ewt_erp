// lib/screens/security/app_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/app_lock_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/snackbar_helper.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _submitting = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (mounted) setState(() => _bioAvailable = canCheck || supported);
    } catch (_) {
      if (mounted) setState(() => _bioAvailable = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlockWithPin() async {
    final lock = context.read<AppLockProvider>();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (lock.verifyPin(_pinController.text.trim())) {
        lock.markUnlocked();
        // Do not navigate; AuthWrapper will rebuild to AppShell once unlocked
      } else {
        setState(() => _error = 'Invalid PIN');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _unlockWithBiometrics() async {
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock MISK ERP',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!mounted) return;
      if (didAuth) {
        context.read<AppLockProvider>().markUnlocked();
        // No navigation here; let AuthWrapper show AppShell
      } else {
        SnackbarHelper.showInfo(context, 'Biometric authentication cancelled');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Biometric error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockProvider>();
    return Scaffold(
      backgroundColor: MiskTheme.miskCream,
      appBar: AppBar(
        title: const Text('Unlock'),
        // rely on theme AppBar colors for consistency
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'App is locked',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your PIN to continue',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => _unlockWithPin(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _unlockWithPin,
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : const Text('Unlock'),
                ),
              ),
              if (lock.biometricEnabled && _bioAvailable) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _unlockWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use biometrics'),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
