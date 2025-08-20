import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:misk_ewt_erp/screens/dashboard_screen.dart';
//import 'package:misk_ewt_erp/screens/members_page.dart';
import 'package:misk_ewt_erp/screens/login_screen.dart';
//import 'package:misk_ewt_erp/screens/project_list_screen.dart';
import 'package:misk_ewt_erp/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter and Firebase are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set system UI overlay style for MISK branding
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.primaryGreen,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.lightBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MISKTrustApp());
}

class MISKTrustApp extends StatelessWidget {
  const MISKTrustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App Configuration
      title: 'MISK Educational & Welfare Trust',
      debugShowCheckedModeBanner: false,

      // Apply MISK Theme
      theme: AppTheme.lightTheme,

      // App Routes
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        //'/projects': (context) => const ProjectListScreen(),
        //'/members': (context) => const MembersPage(),
        // Add more routes as you create additional screens
        '/events': (context) => const PlaceholderScreen(title: 'Events'),
        '/initiatives': (context) => const PlaceholderScreen(title: 'Initiatives'),
        '/tasks': (context) => const PlaceholderScreen(title: 'Tasks'),
        '/finance': (context) => const PlaceholderScreen(title: 'Finance'),
        '/reports': (context) => const PlaceholderScreen(title: 'Reports'),
        '/settings': (context) => const PlaceholderScreen(title: 'Settings'),
      },

      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const PlaceholderScreen(title: 'Page Not Found'),
        );
      },

      // Global theme configuration
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const MISKScrollBehavior(),
          child: child!,
        );
      },
    );
  }
}

// Custom scroll behavior for MISK app
class MISKScrollBehavior extends ScrollBehavior {
  const MISKScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: AppTheme.primaryGreen,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

// Placeholder screen for routes not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // MISK Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction,
                  size: 40,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                '$title Module',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'This feature is under development and will be available soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Back Button
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Support Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feature will be implemented in next update',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
