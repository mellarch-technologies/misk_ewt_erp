import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _canCheckBiometrics = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedCredentials();
    _checkBiometrics();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final rememberMe = prefs.getBool('remember_me') ?? false;
      
      if (savedEmail != null && rememberMe) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      setState(() {
        _canCheckBiometrics = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      setState(() {
        _canCheckBiometrics = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_canCheckBiometrics) return;
    
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access MISK Trust ERP',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      
      if (didAuthenticate) {
        // Load saved credentials and auto-login
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('saved_email');
        final savedPassword = prefs.getString('saved_password');
        
        if (savedEmail != null && savedPassword != null) {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          await _performLogin();
        }
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      _showErrorMessage('Biometric authentication failed');
    }
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Authenticate with Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Save credentials if Remember Me is checked
      if (_rememberMe) {
        await _saveCredentials();
      } else {
        await _clearSavedCredentials();
      }
      
      // Navigate to dashboard
      if (mounted && credential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled. Contact administrator.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed. Please try again.';
      }
      _showErrorMessage(errorMessage);
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
      // Note: For production, consider using more secure storage for passwords
      await prefs.setString('saved_password', _passwordController.text.trim());
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: MiskTheme.greenGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MiskTheme.spacingLarge),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: MiskTheme.spacingXLarge),
                            _buildEmailField(),
                            const SizedBox(height: MiskTheme.spacingMedium),
                            _buildPasswordField(),
                            const SizedBox(height: MiskTheme.spacingMedium),
                            _buildRememberMeAndForgotPassword(),
                            const SizedBox(height: MiskTheme.spacingXLarge),
                            _buildLoginButton(),
                            if (_canCheckBiometrics) ...[
                              const SizedBox(height: MiskTheme.spacingLarge),
                              _buildBiometricButton(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // MISK Logo
        Container(
          width: 100,
          height: 100,
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
            Icons.mosque,
            size: 50,
            color: MiskTheme.miskWhite,
          ),
        ),
        
        const SizedBox(height: MiskTheme.spacingLarge),
        
        Text(
          'MISK Trust',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: MiskTheme.miskDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        Text(
          'Educational & Welfare Trust',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MiskTheme.miskTextDark.withOpacity(0.7),
          ),
        ),
        
        const SizedBox(height: MiskTheme.spacingSmall),
        
        Text(
          'ERP System Login',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MiskTheme.miskGold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email address',
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

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _performLogin(),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter your password';
        }
        if (value!.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: Text(
                'Remember Me',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen(),
              ),
            );
          },
          child: const Text('Forgot Password?'),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _performLogin,
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
                  const Text('Signing In...'),
                ],
              )
            : const Text('Login'),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: MiskTheme.miskLightGreen.withOpacity(0.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
              child: Text(
                'OR',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MiskTheme.miskTextDark.withOpacity(0.6),
                ),
              ),
            ),
            Expanded(child: Divider(color: MiskTheme.miskLightGreen.withOpacity(0.5))),
          ],
        ),
        const SizedBox(height: MiskTheme.spacingMedium),
        OutlinedButton.icon(
          onPressed: _authenticateWithBiometrics,
          icon: const Icon(Icons.fingerprint),
          label: const Text('Use Biometric Login'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}