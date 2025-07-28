// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(MiskTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (v) => email = v!.trim(),
                validator: (v) => v == null || !v.contains('@') ? 'Invalid' : null,
              ),
              const SizedBox(height: MiskTheme.spacingLarge),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    auth.forgotPassword(email).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reset link sent')));
                      Navigator.pop(context);
                    });
                  }
                },
                child: const Text('Send Reset Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}