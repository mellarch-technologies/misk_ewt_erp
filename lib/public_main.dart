// lib/public_main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'public_firebase_options.dart';
import 'theme/app_theme.dart';
import 'public_app/screens/public_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: PublicFirebaseOptions.currentPlatform);
  runApp(const MiskPublicApp());
}

class MiskPublicApp extends StatelessWidget {
  const MiskPublicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MISK — Public Portal',
      debugShowCheckedModeBanner: false,
      theme: MiskTheme.lightTheme,
      home: const PublicHomeScreen(),
    );
  }
}
