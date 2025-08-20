import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
      
      _showSuccessMessage();
      
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send reset email. Please try again.';
      }
      _showErrorMessage(errorMessage);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('An unexpected error occurred. Please try again.');
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Password reset email sent successfully!'),
            ),
          ],
        ),
        backgroundColor: MiskTheme.miskLightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MiskTheme.miskErrorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiskTheme.miskCream,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MiskTheme.miskDarkGreen,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MiskTheme.spacingLarge),
                child: Card(
                  elevation: MiskTheme.elevationHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MiskTheme.borderRadiusXLarge),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(MiskTheme.spacingXLarge),
                    decoration: BoxDecoration(
                      color: MiskTheme.miskWhite,
                      borderRadius: BorderRadius.circular(MiskTheme.borderRadiusXLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: _emailSent ? _buildSuccessContent() : _buildResetForm(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: MiskTheme.spacingXLarge),
          _buildInstructions(),
          const SizedBox(height: MiskTheme.spacingLarge),
          _buildEmailField(),
          const SizedBox(height: MiskTheme.spacingXLarge),
          _buildResetButton(),
          const SizedBox(height: MiskTheme.spacingMedium),
          _buildBackToLoginButton(),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: MiskTheme.miskLightGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MiskTheme.miskLightGreen.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.mail_outline,
            size: 40,
            color: MiskTheme.miskWhite,
          ),
        ),
        
        const SizedBox(height: MiskTheme.spacingLarge),
        
        Text(
          'Email Sent!',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: MiskTheme.miskDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: MiskTheme.spacingMedium),
        
        Text(
          'We\'ve sent a password reset link to:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MiskTheme.miskTextDark.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: MiskTheme.spacingSmall),
        
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MiskTheme.spacingMedium,
            vertical: MiskTheme.spacingSmall,
          ),
          decoration: BoxDecoration(
            color: MiskTheme.miskGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(MiskTheme.borderRadiusSmall),
            border: Border.all(
              color: MiskTheme.miskGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            _emailController.text.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MiskTheme.miskDarkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: MiskTheme.spacingLarge),
        
        _buildInstructionsList(),
        
        const SizedBox(height: MiskTheme.spacingXLarge),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _emailSent = false;
                  });
                },
                child: const Text('Send Again'),
              ),
            ),
            const SizedBox(width: MiskTheme.spacingMedium),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Reset Password Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: MiskTheme.goldGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MiskTheme.miskGold.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset,
            size: 40,
            color: MiskTheme.miskWhite,
          ),
        ),
        
        const SizedBox(height: MiskTheme.spacingLarge),
        
        Text(
          'Reset Password',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: MiskTheme.miskDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: MiskTheme.spacingSmall),
        
        Text(
          'MISK Trust ERP',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MiskTheme.miskGold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(MiskTheme.spacingMedium),
      decoration: BoxDecoration(
        color: MiskTheme.miskLightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
        border: Border.all(
          color: MiskTheme.miskLightGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: MiskTheme.miskLightGreen,
            size: 20,
          ),
          const SizedBox(width: MiskTheme.spacingSmall),
          Expanded(
            child: Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MiskTheme.miskTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _resetPassword(),
      decoration: const InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your registered email address',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return 'Please enter your email address';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(MiskTheme.miskWhite),
                    ),
                  ),
                  const SizedBox(width: MiskTheme.spacingMedium),
                  const Text('Sending Reset Email...'),
                ],
              )
            : const Text('Send Reset Email'),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back_outlined),
      label: const Text('Back to Login'),
      style: TextButton.styleFrom(
        foregroundColor: MiskTheme.miskDarkGreen,
      ),
    );
  }

  Widget _buildInstructionsList() {
    final instructions = [
      'Check your email inbox for the reset link',
      'Click on the link in the email',
      'Create a new strong password',
      'Return to login with your new password',
    ];

    return Container(
      padding: const EdgeInsets.all(MiskTheme.spacingMedium),
      decoration: BoxDecoration(
        color: MiskTheme.miskCream.withOpacity(0.5),
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
        border: Border.all(
          color: MiskTheme.miskLightGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Steps:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: MiskTheme.miskDarkGreen,
            ),
          ),
          const SizedBox(height: MiskTheme.spacingSmall),
          ...instructions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: MiskTheme.spacingXSmall),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: MiskTheme.miskGold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: MiskTheme.miskWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MiskTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MiskTheme.miskTextDark.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}