import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:misk_ewt_erp/screens/dashboard_screen.dart';
import 'package:misk_ewt_erp/providers/app_auth_provider.dart';
import 'package:misk_ewt_erp/providers/user_provider.dart';
import 'package:misk_ewt_erp/providers/permission_provider.dart';
import 'package:misk_ewt_erp/providers/role_provider.dart';
import 'package:misk_ewt_erp/models/user_model.dart';

// Test fakes to avoid Firebase and heavy logic during widget tests
class _FakeAppAuthProvider extends ChangeNotifier implements AppAuthProvider {
  @override
  bool get isLoading => false;
  @override
  firebase_auth.User? get user => null; // no logged-in user
  // New getters from throttling
  @override
  bool get isLockedOut => false;
  @override
  Duration? get lockoutRemaining => null;
  @override
  Future<void> forgotPassword(String email) async {}
  @override
  Future<void> login(String email, String password) async {}
  @override
  Future<void> logout() async {}
}

class _FakeUserProvider extends ChangeNotifier implements UserProvider {
  @override
  bool get hasError => false;

  @override
  bool get isBusy => false;

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  String? get errorMessage => null;

  @override
  List<UserModel> get users => const [];

  @override
  Future<void> fetchUsers({bool refresh = false}) async {}

  @override
  UserModel? getCurrentUserByEmail(String? email) => null;

  @override
  Future<void> removeUser(String uid) async {}

  @override
  Future<void> saveUser(UserModel user) async {}

  @override
  void setFilter(String query) {}
}

void main() {
  Widget _wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppAuthProvider>(create: (_) => _FakeAppAuthProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => _FakeUserProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('DashboardScreen Widget Tests', () {
    testWidgets('Dashboard loads and displays key UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithProviders(const DashboardScreen()));
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('MISK ERP'), findsOneWidget);
      // Welcome card text (updated)
      expect(find.text('Welcome to MISK ERP Mini'), findsOneWidget);
      // Current user section label
      expect(find.textContaining('Current User:'), findsOneWidget);
    });

    testWidgets('Floating action button opens seed options', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithProviders(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Tap the actual FAB icon used by the app
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Seed Initiatives'), findsOneWidget);
      expect(find.text('Seed Campaigns'), findsOneWidget);
      expect(find.text('Seed Tasks'), findsOneWidget);
    });
  });
}
