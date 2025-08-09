import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/app_auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/permission_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/users/users_list_screen.dart';
import 'screens/users/user_form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MiskEwtErpApp());
}

class MiskEwtErpApp extends StatelessWidget {
  const MiskEwtErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: MaterialApp(
        title: 'MISK EWT ERP',
        debugShowCheckedModeBanner: false,
        theme: MiskTheme.lightTheme,
        routes: {
          '/login': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/users_list': (_) => const UsersListScreen(),
          '/users': (_) => const UsersListScreen(),
          '/users/form': (_) => const UserFormScreen(),
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  firebase_auth.User? _lastUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use Provider.of here because we are outside the build method of AuthWrapper
    final auth = Provider.of<AppAuthProvider>(context);

    if (auth.user != _lastUser) {
      if (auth.user != null && _lastUser == null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login Successful! Welcome to MISK ERP.'),
                duration: Duration(seconds: 3),
              ),
            );
          });
        }
      }
      _lastUser = auth.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Correctly watch the AppAuthProvider for build method
    final auth = context.watch<AppAuthProvider>();

    if (auth.user != null) {
      return const DashboardScreen();
    }
    return const LoginScreen();
  }
}
