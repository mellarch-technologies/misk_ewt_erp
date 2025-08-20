import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  String _userRole = 'Member'; // Default role
  String _userName = 'User';
  String _userDesignation = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        // In real implementation, fetch role from Firestore user document
        _userRole = 'Trustee'; // Demo: This would come from user's Firestore document
        _userDesignation = 'Administrator'; // Demo designation
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, $_userName', style: const TextStyle(fontSize: 18)),
            if (_userDesignation.isNotEmpty)
              Text(
                _userDesignation,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          // Quick stats for admins
          if (_userRole == 'Trustee' || _userRole == 'Admin')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Show notifications
                },
                tooltip: 'Notifications',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section with personalized greeting
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Quick stats section (admin/trustee only)
            if (_userRole == 'Trustee' || _userRole == 'Admin') ...[
              _buildQuickStatsSection(),
              const SizedBox(height: 24),
            ],

            // Main navigation grid
            _buildNavigationGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good Evening';
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) greeting = 'Good Afternoon';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.gradientDecoration(
        startColor: AppTheme.primaryGreen,
        endColor: AppTheme.darkBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $_userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'MISK Educational & Welfare Trust',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'May Allah bless your efforts in serving the community',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Active Members',
                value: '248',
                icon: Icons.people,
                color: AppTheme.memberPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Ongoing Events',
                value: '12',
                icon: Icons.event,
                color: AppTheme.eventBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Donations',
                value: '₹1.2L',
                icon: Icons.volunteer_activism,
                color: AppTheme.donationGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Tasks Pending',
                value: '7',
                icon: Icons.task_alt,
                color: AppTheme.warningOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationGrid() {
    // Define all possible dashboard items with their access roles
    final List<DashboardItem> allItems = [
      DashboardItem(
        title: 'Members',
        subtitle: 'Manage community members',
        icon: Icons.people_outline,
        route: '/members',
        color: AppTheme.memberPurple,
        roles: ['Trustee', 'Admin', 'Staff'],
      ),
      DashboardItem(
        title: 'Events',
        subtitle: 'Organize and track events',
        icon: Icons.event_note,
        route: '/events',
        color: AppTheme.eventBlue,
        roles: ['Trustee', 'Admin', 'Staff', 'Member'],
      ),
      DashboardItem(
        title: 'Initiatives',
        subtitle: 'Community projects & campaigns',
        icon: Icons.lightbulb_outline,
        route: '/initiatives',
        color: AppTheme.primaryGreen,
        roles: ['Trustee', 'Admin', 'Staff'],
      ),
      DashboardItem(
        title: 'Tasks',
        subtitle: 'Personal & team tasks',
        icon: Icons.task_alt,
        route: '/tasks',
        color: AppTheme.accentGold,
        roles: ['Trustee', 'Admin', 'Staff', 'Member'],
      ),
      DashboardItem(
        title: 'Finance',
        subtitle: 'Budget & donations tracking',
        icon: Icons.account_balance_wallet,
        route: '/finance',
        color: AppTheme.financeOrange,
        roles: ['Trustee', 'Admin'],
      ),
      DashboardItem(
        title: 'Projects',
        subtitle: 'Infrastructure projects',
        icon: Icons.architecture,
        route: '/projects',
        color: AppTheme.darkBlue,
        roles: ['Trustee', 'Admin', 'Staff'],
      ),
      DashboardItem(
        title: 'Reports',
        subtitle: 'Analytics & insights',
        icon: Icons.analytics,
        route: '/reports',
        color: AppTheme.successGreen,
        roles: ['Trustee', 'Admin'],
      ),
      DashboardItem(
        title: 'Settings',
        subtitle: 'App configuration',
        icon: Icons.settings,
        route: '/settings',
        color: AppTheme.textMedium,
        roles: ['Trustee'],
      ),
    ];

    // Filter items based on user role
    final accessibleItems = allItems
        .where((item) => item.roles.contains(_userRole))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: accessibleItems.length,
          itemBuilder: (context, index) {
            final item = accessibleItems[index];
            return _buildNavigationCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildNavigationCard(DashboardItem item) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(item.route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color,
                item.color.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Data class for dashboard items
class DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
  final List<String> roles;

  DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
    required this.roles,
  });
}
