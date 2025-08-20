// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final auth = context.read<AppAuthProvider>();
    try {
      await auth.forgotPassword(_email);
      setState(() => _successMessage = 'Password reset link sent! Please check your email inbox (and spam folder).');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MiskTheme.spacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_reset, size: 60, color: MiskTheme.miskGold),
                const SizedBox(height: MiskTheme.spacingLarge),
                Text(
                  'Forgot Your Password?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MiskTheme.spacingMedium),
                Text(
                  'Enter your email address below, and we will send you a link to create a new password.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: MiskTheme.spacingXLarge),
                if (_successMessage == null)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (v) => _email = v!.trim(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                const SizedBox(height: MiskTheme.spacingLarge),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: MiskTheme.miskErrorRed, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(MiskTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: MiskTheme.miskDarkGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
                    ),
                    child: Text(
                      _successMessage!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: MiskTheme.miskDarkGreen, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: MiskTheme.spacingXLarge),
                if (_successMessage == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetLink,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: MiskTheme.miskWhite,
                              ),
                            )
                          : const Text('Send Reset Link'),
                    ),
                  ),
                const SizedBox(height: MiskTheme.spacingMedium),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
