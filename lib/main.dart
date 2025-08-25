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
import 'providers/app_lock_provider.dart';

import 'screens/login_screen.dart';
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
import 'screens/security/app_lock_screen.dart';
import 'screens/dashboard_v2_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/snackbar_helper.dart';

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
        // App Lock provider with async load
        ChangeNotifierProvider(create: (_) => AppLockProvider()..load()),
      ],
      child: MaterialApp(
        title: 'MISK ERP',
        theme: MiskTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AppShell(),
          '/login': (_) => const LoginScreen(),
          // Ensure dashboard route loads the shell (left nav) instead of a standalone screen
          '/dashboard': (_) => AppShell(key: AppShell.shellKey),
          '/dashboard_v2': (context) => const DashboardV2Screen(), // Labs route
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
  bool _showedWelcome = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AppAuthProvider>(context);

    // Detect login transition
    if (auth.user != _lastUser) {
      // Load/clear permissions on auth change
      final perm = Provider.of<PermissionProvider>(context, listen: false);
      if (auth.user != null) {
        // Load permissions by email
        perm.loadForEmail(auth.user!.email);
      } else {
        // Clear permissions on logout
        perm.clearPermissions();
      }

      // If newly logged in, show welcome once
      if (auth.user != null && _lastUser == null && !_showedWelcome) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SnackbarHelper.showSuccess(context, 'Login Successful! Welcome to MISK ERP.');
          });
          _showedWelcome = true;
        }
      }
      _lastUser = auth.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final appLock = context.watch<AppLockProvider>();

    if (auth.user != null) {
      // If logged in and app lock requires unlock, show lock screen
      if (appLock.enabled && appLock.shouldLockNow()) {
        return const AppLockScreen();
      }
      return AppShell(key: AppShell.shellKey);
    } else {
      // Reset welcome state so next login shows snackbar again
      if (_showedWelcome) _showedWelcome = false;
      return const LoginScreen();
    }
  }
}

class AppLifecycleWatcher extends StatefulWidget {
  final Widget child;
  const AppLifecycleWatcher({super.key, required this.child});

  @override
  State<AppLifecycleWatcher> createState() => _AppLifecycleWatcherState();
}

class _AppLifecycleWatcherState extends State<AppLifecycleWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock on background/inactive
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      final appLock = context.read<AppLockProvider>();
      appLock.forceLockNow();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
