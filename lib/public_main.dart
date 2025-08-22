// lib/public_main.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'public_app/screens/donate_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const DonateHomeScreen(),
    );
  }
}
