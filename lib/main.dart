// lib/main.dart  (v1.2)
// Updated to include MemberProvider and route mapping for Members module.
// Compatible with MISK Theme constants.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/member_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/members/members_list_screen.dart';
import 'screens/users/user_form_screen.dart';
import 'screens/users/users_list_screen.dart';
import 'screens/forgot_password_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set transparent status bar, light icons; white nav bar.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const MiskEwtErpApp());
}

class MiskEwtErpApp extends StatelessWidget {
  const MiskEwtErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        //ChangeNotifierProvider(create: (_) => MemberProvider()..fetchMembers()),
      ],
      child: MaterialApp(
        title: 'MISK EWT ERP',
        debugShowCheckedModeBanner: false,
        theme: MiskTheme.lightTheme,
        routes: {
          '/login': (_) => const LoginScreen(),
          '/forgot': (_) => const ForgotPasswordScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/users': (_) => const UsersListScreen(),
          '/users/form': (_) => const UserFormScreen(),
        },
        home: StreamBuilder<firebase_auth.User?>(
          stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AuthLoadingScreen();
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const DashboardScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiskTheme.miskCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: MiskTheme.miskGold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: MiskTheme.miskGold.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.mosque, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'MISK Trust',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: MiskTheme.miskDarkGreen,
              ),
            ),
            Text(
              'Educational & Welfare Trust',
              style: TextStyle(
                fontSize: 16,
                color: MiskTheme.miskTextDark.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MiskTheme.miskGold),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 14,
                color: MiskTheme.miskTextDark.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}