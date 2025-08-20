// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:misk_ewt_erp/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';
import '../widgets/snackbar_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false; // Use local state for loading indicator

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AppAuthProvider>();

    try {
      await authProvider.login(_email.trim(), _password);
      // Explicitly navigate to dashboard on success to ensure immediate redirect
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        SnackbarHelper.showSuccess(context, 'Login Successful! Welcome to MISK ERP.');
      }
    } on AuthFailure catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final lockedOut = auth.isLockedOut;
    final remaining = auth.lockoutRemaining;
    String? remainingText;
    if (lockedOut && remaining != null) {
      final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      remainingText = '$m:$s';
    }

    return Scaffold(
      backgroundColor: MiskTheme.miskCream, // Use theme color
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/misk_logo.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.mosque, size: 100, color: MiskTheme.miskDarkGreen),
                ),
                const SizedBox(height: 24),
                Text('Welcome Back', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('Sign in to your MISK account', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 40),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: MiskTheme.miskErrorRed, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (lockedOut)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_clock, color: MiskTheme.miskErrorRed),
                        const SizedBox(width: 8),
                        Text(
                          'Too many failed attempts. Try again in ${remainingText ?? ''}',
                          style: const TextStyle(color: MiskTheme.miskErrorRed, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        enabled: !lockedOut && !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // Basic regex for email validation
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value!.trim(),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        enabled: !lockedOut && !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: lockedOut ? null : _togglePasswordVisibility,
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                        onSaved: (value) => _password = value!,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: (_isLoading || lockedOut)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isLoading || lockedOut) ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: MiskTheme.miskWhite,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
