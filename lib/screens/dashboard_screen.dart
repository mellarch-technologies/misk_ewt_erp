// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../providers/app_auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/permission_provider.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

      await userProvider.fetchUsers();

      final firebaseUser = authProvider.user;
      if (firebaseUser != null) {
        final currentUserModel = userProvider.users.firstWhereOrNull((u) => u.email == firebaseUser.email);
        await permissionProvider.loadUserPermissions(currentUserModel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final permissionProvider = context.watch<PermissionProvider>();

    final firebaseUser = auth.user;
    final appUser = userProvider.users.firstWhereOrNull((u) => u.email == firebaseUser?.email);

    final userName = appUser?.name ?? firebaseUser?.email?.split('@').first ?? 'User';
    final designation = appUser?.designation ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/misk_logo.png', errorBuilder: (context, error, stackTrace) => const Icon(Icons.mosque)),
        ),
        leadingWidth: 70,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
            onPressed: () { /* Dummy Action */ },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              // Show confirmation dialog before logging out
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false), // No
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true), // Yes
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ) ?? false; // Default to false if dialog is dismissed

              if (confirmed) {
                permissionProvider.clearPermissions();
                await auth.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: permissionProvider.isLoading || userProvider.isBusy
          ? const Center(child: CircularProgressIndicator(color: MiskTheme.miskGold))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(
              userName: userName,
              roleName: permissionProvider.roleName,
              designation: designation,
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: "My Pending Tasks"),
            const SizedBox(height: 12),
            _MyTaskItem(title: "Prepare Annual Report", dueDate: "Due in 3 days", progress: 0.75),
            _MyTaskItem(title: "Follow up with new members", dueDate: "Due tomorrow", progress: 0.2),
            const SizedBox(height: 24),

            if (permissionProvider.can('can_view_all_modules')) ...[
              const _SectionHeader(title: "Organizational Overview"),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatOverviewCard(value: "12", label: "Pending Tasks", color: Colors.orange.shade700),
                  const SizedBox(width: 16),
                  _StatOverviewCard(value: "3", label: "Overdue Tasks", color: Colors.red.shade700),
                ],
              ),
              const SizedBox(height: 16),
              _InitiativeCard(
                  title: "Masjid Construction Fund",
                  progress: 0.6,
                  collected: "₹1,20,000",
                  goal: "₹2,00,000"
              ),
              const SizedBox(height: 24),
            ],

            const _SectionHeader(title: "Modules"),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (permissionProvider.can('can_manage_users'))
                  _ModuleCard(icon: Icons.people_alt, title: "Members", onTap: () {}),
                if (permissionProvider.can('can_view_finances'))
                  _ModuleCard(icon: Icons.account_balance_wallet, title: "Accounting", onTap: () {}),
                if (permissionProvider.can('can_manage_events'))
                  _ModuleCard(icon: Icons.event, title: "Events", onTap: () {}),
                if (permissionProvider.can('can_view_tasks'))
                  _ModuleCard(icon: Icons.task_alt, title: "Tasks", onTap: () {}),
                if (permissionProvider.can('can_view_madrasah_stats'))
                  _ModuleCard(icon: Icons.school, title: "Madrasah", onTap: () {}),
              ],
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: "Recent Activity"),
            const SizedBox(height: 12),
            _RecentActivityItem(icon: Icons.person_add, title: "New member 'Zayd' joined.", time: "2h ago"),
            _RecentActivityItem(icon: Icons.event, title: "Annual General Meeting published.", time: "1d ago"),
          ],
        ),
      ),
    );
  }
}

// All reusable UI component widgets (_SectionHeader, _WelcomeCard, _InfoChip, _MyTaskItem,
// _StatOverviewCard, _ModuleCard, _InitiativeCard, _RecentActivityItem) remain the same.
// (You can copy them from the previous complete dashboard_screen.dart file if you need them)

// Header for each section
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}

// Top welcome card
class _WelcomeCard extends StatelessWidget {
  final String userName;
  final String roleName;
  final String designation;

  const _WelcomeCard({required this.userName, required this.roleName, required this.designation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: MiskTheme.miskDarkGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "صباح الخير",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MiskTheme.miskGold),
            ),
            const SizedBox(height: 4),
            Text(
              "Welcome back, $userName",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(label: roleName, icon: Icons.verified_user_outlined),
                if (designation.isNotEmpty) const SizedBox(width: 12),
                if (designation.isNotEmpty)
                  _InfoChip(label: designation, icon: Icons.work_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Small chip for role/designation
class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

// Task item for the user's personal list
class _MyTaskItem extends StatelessWidget {
  final String title;
  final String dueDate;
  final double progress;

  const _MyTaskItem({required this.title, required this.dueDate, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dueDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("${(progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: MiskTheme.miskGold,
            ),
          ],
        ),
      ),
    );
  }
}

// Card for overall stats
class _StatOverviewCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatOverviewCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Card for module navigation
class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ModuleCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 24.5,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)) ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: MiskTheme.miskDarkGreen),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Card for initiatives/campaigns
class _InitiativeCard extends StatelessWidget {
  final String title;
  final double progress;
  final String collected;
  final String goal;

  const _InitiativeCard({required this.title, required this.progress, required this.collected, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade300,
                    color: MiskTheme.miskGold,
                  ),
                  Center(child: Text("${(progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("$collected / $goal", style: const TextStyle(color: Colors.black54)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Item for the recent activity feed
class _RecentActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  const _RecentActivityItem({required this.icon, required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.black54))),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
