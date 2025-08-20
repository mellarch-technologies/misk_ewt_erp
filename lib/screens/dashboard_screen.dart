import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/app_auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/permission_provider.dart';
import '../theme/app_theme.dart';
import '../services/initiative_service.dart';
import '../services/campaign_service.dart';
import '../services/task_service.dart';
import '../services/event_announcement_service.dart';
import '../widgets/snackbar_helper.dart';
import '../widgets/kpi_card.dart';
import 'donations/donations_entry_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void>? _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

    await userProvider.fetchUsers();

    final firebaseUser = authProvider.user;
    if (firebaseUser != null && mounted) {
      final currentUserModel = userProvider.getCurrentUserByEmail(firebaseUser.email);
      if (currentUserModel != null) {
        await permissionProvider.loadUserPermissions(currentUserModel);
      }
    }
  }

  Future<int> _countOf(String collection) async {
    // Simple count via get; fine for small/medium datasets. Can switch to aggregation later.
    final snap = await FirebaseFirestore.instance.collection(collection).get();
    return snap.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MISK ERP'),
        backgroundColor: MiskTheme.miskGold,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: MiskTheme.miskGold),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/misk_logo.png', height: 40),
                  const SizedBox(height: 8),
                  const Text('MISK ERP Mini', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              onTap: () => Navigator.pushNamed(context, '/users'),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Roles'),
              onTap: () => Navigator.pushNamed(context, '/roles'),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Initiatives'),
              onTap: () => Navigator.pushNamed(context, '/initiatives'),
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Campaigns'),
              onTap: () { Navigator.pushNamed(context, '/campaigns'); },
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('Tasks'),
              onTap: () { Navigator.pushNamed(context, '/tasks'); },
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Donations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonationsEntryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Events & Announcements'),
              onTap: () { Navigator.pushNamed(context, '/events_announcements'); },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () { Navigator.pushNamed(context, '/settings'); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
                await authProvider.logout();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: MiskTheme.miskGold));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Welcome to MISK ERP Mini', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Use the navigation drawer to access different modules.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final user = Provider.of<AppAuthProvider>(context).user;
                    final currentUser = user != null ? userProvider.getCurrentUserByEmail(user.email) : null;

                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current User: ${currentUser?.name ?? 'Unknown'}', style: const TextStyle(fontSize: 18)),
                            if (currentUser != null) ...[
                              const SizedBox(height: 8),
                              Text('Email: ${currentUser.email}'),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // KPI cards
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    KpiCard(title: 'Users', icon: Icons.people, loadCount: () => _countOf('users')),
                    KpiCard(title: 'Roles', icon: Icons.security, loadCount: () => _countOf('roles')),
                    KpiCard(title: 'Initiatives', icon: Icons.flag, loadCount: () => _countOf('initiatives')),
                    KpiCard(title: 'Campaigns', icon: Icons.campaign, loadCount: () => _countOf('campaigns')),
                    KpiCard(title: 'Tasks', icon: Icons.task, loadCount: () => _countOf('tasks')),
                    KpiCard(title: 'Events', icon: Icons.event, loadCount: () => _countOf('events_announcements')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final rootContext = context; // capture parent context
          showModalBottomSheet(
            context: context,
            builder: (sheetContext) => Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Seed Initiatives'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await InitiativeService().seedSampleInitiatives();
                        if (mounted) {
                          SnackbarHelper.showSuccess(rootContext, 'Initiatives seeded successfully');
                        }
                      } catch (e) {
                        if (mounted) {
                          SnackbarHelper.showError(rootContext, 'Error seeding initiatives: $e');
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Seed Campaigns'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await CampaignService().seedSampleCampaigns();
                        if (mounted) {
                          SnackbarHelper.showSuccess(rootContext, 'Campaigns seeded successfully');
                        }
                      } catch (e) {
                        if (mounted) {
                          SnackbarHelper.showError(rootContext, 'Error seeding campaigns: $e');
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Seed Tasks'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await TaskService().seedSampleTasks();
                        if (mounted) {
                          SnackbarHelper.showSuccess(rootContext, 'Tasks seeded successfully');
                        }
                      } catch (e) {
                        if (mounted) {
                          SnackbarHelper.showError(rootContext, 'Error seeding tasks: $e');
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Seed Events/Announcements'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await EventAnnouncementService().seedSampleEvents();
                        if (mounted) {
                          SnackbarHelper.showSuccess(rootContext, 'Events & Announcements seeded successfully');
                        }
                      } catch (e) {
                        if (mounted) {
                          SnackbarHelper.showError(rootContext, 'Error seeding events: $e');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: MiskTheme.miskGold,
        child: const Icon(Icons.add),
      ),
    );
  }
}
