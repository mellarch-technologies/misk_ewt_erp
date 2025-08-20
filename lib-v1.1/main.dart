import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/app_auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/permission_provider.dart';
import 'providers/role_provider.dart';
import 'providers/initiative_provider.dart';
import 'providers/campaign_provider.dart';
import 'providers/task_provider.dart';
import 'providers/event_announcement_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/users/users_list_screen.dart';
import 'screens/users/user_form_screen.dart';
import 'screens/roles/roles_list_screen.dart';
import 'screens/roles/role_form_screen.dart';
import 'screens/settings/global_settings_screen.dart';
import 'screens/initiatives/initiatives_list_screen.dart';
import 'screens/initiatives/initiative_form_screen.dart';
import 'screens/campaigns/campaigns_list_screen.dart';
import 'screens/campaigns/campaign_form_screen.dart';
import 'screens/tasks/tasks_list_screen.dart';
import 'screens/tasks/task_form_screen.dart';
import 'screens/events_announcements/events_announcements_list_screen.dart';
import 'screens/events_announcements/event_announcement_form_screen.dart';

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
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => InitiativeProvider()),
        ChangeNotifierProvider(create: (_) => CampaignProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => EventAnnouncementProvider()),
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
          '/roles': (_) => const RolesListScreen(),
          '/roles/form': (_) => const RoleFormScreen(),
          '/settings': (_) => const GlobalSettingsScreen(),
          '/initiatives': (_) => InitiativesListScreen(),
          '/initiatives/form': (_) => InitiativeFormScreen(),
          '/campaigns': (_) => CampaignsListScreen(),
          '/campaigns/form': (_) => CampaignFormScreen(),
          '/tasks': (_) => TasksListScreen(),
          '/tasks/form': (_) => TaskFormScreen(),
          '/events_announcements': (_) => EventsAnnouncementsListScreen(),
          '/events_announcements/form': (_) => EventAnnouncementFormScreen(),
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
    final auth = context.watch<AppAuthProvider>();

    if (auth.user != null) {
      return const DashboardScreen();
    }
    return const LoginScreen();
  }
}
