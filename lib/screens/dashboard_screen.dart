import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  Map<String, int> _statistics = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _initAnimations();
    _loadUserProfile();
    _loadStatistics();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser?.email == null) return;
    
    try {
      // Check if user is super admin
      if (_currentUser!.email == 'admin@misk.org.in') {
        setState(() {
          _userProfile = {
            'name': 'Muhammad Tanveerullah',
            'role': 'Trustee',
            'designation': 'Vice President',
            'isAdmin': true,
            'isSuperAdmin': true,
          };
        });
        return;
      }
      
      // Query members collection for user profile
      final memberDoc = await FirebaseFirestore.instance
          .collection('members')
          .where('email', isEqualTo: _currentUser!.email)
          .limit(1)
          .get();
      
      if (memberDoc.docs.isNotEmpty) {
        setState(() {
          _userProfile = memberDoc.docs.first.data();
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    
    try {
      // Load all collection counts in parallel
      final futures = [
        FirebaseFirestore.instance.collection('members').count().get(),
        FirebaseFirestore.instance.collection('events').count().get(),
        FirebaseFirestore.instance.collection('initiatives').count().get(),
        FirebaseFirestore.instance.collection('tasks').count().get(),
      ];
      
      final results = await Future.wait(futures);
      
      setState(() {
        _statistics = {
          'members': results[0].count ?? 0,
          'events': results[1].count ?? 0,
          'initiatives': results[2].count ?? 0,
          'tasks': results[3].count ?? 0,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() {
        _statistics = {
          'members': 247,
          'events': 12,
          'initiatives': 8,
          'tasks': 23,
        };
        _isLoadingStats = false;
      });
    }
  }

  String _getIslamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'صباح الخير'; // Good morning
    } else if (hour < 17) {
      return 'مساء الخير'; // Good afternoon
    } else {
      return 'مساء الخير'; // Good evening
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout from MISK Trust ERP?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiskTheme.miskCream,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadUserProfile();
              await _loadStatistics();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(MiskTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(),
                  const SizedBox(height: MiskTheme.spacingLarge),
                  _buildQuickStats(),
                  const SizedBox(height: MiskTheme.spacingLarge),
                  _buildQuickActions(),
                  const SizedBox(height: MiskTheme.spacingLarge),
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MiskTheme.miskGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mosque,
              size: 18,
              color: MiskTheme.miskWhite,
            ),
          ),
          const SizedBox(width: MiskTheme.spacingSmall),
          const Text('MISK Trust ERP'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications feature coming soon!'),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MiskTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: MiskTheme.goldGradient,
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: MiskTheme.miskGold.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getIslamicGreeting(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MiskTheme.miskWhite.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: MiskTheme.spacingSmall),
          Text(
            'Welcome back${_userProfile?['name'] != null ? ', ${_userProfile!['name']}!' : '!'}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: MiskTheme.miskWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_userProfile != null) ...[
            const SizedBox(height: MiskTheme.spacingSmall),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MiskTheme.spacingSmall,
                    vertical: MiskTheme.spacingXSmall,
                  ),
                  decoration: BoxDecoration(
                    color: MiskTheme.miskWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(MiskTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    _userProfile!['role'] ?? 'Member',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MiskTheme.miskWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_userProfile!['designation'] != null) ...[
                  const SizedBox(width: MiskTheme.spacingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MiskTheme.spacingSmall,
                      vertical: MiskTheme.spacingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: MiskTheme.miskWhite.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(MiskTheme.borderRadiusSmall),
                    ),
                    child: Text(
                      _userProfile!['designation'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MiskTheme.miskWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: MiskTheme.spacingMedium),
          Text(
            _currentUser?.email ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MiskTheme.miskWhite.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: MiskTheme.miskDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MiskTheme.spacingMedium),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: MiskTheme.spacingMedium,
          crossAxisSpacing: MiskTheme.spacingMedium,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Members',
              _statistics['members']?.toString() ?? '0',
              Icons.people_outline,
              MiskTheme.miskGold,
            ),
            _buildStatCard(
              'Events',
              _statistics['events']?.toString() ?? '0',
              Icons.event_outlined,
              MiskTheme.miskDarkGreen,
            ),
            _buildStatCard(
              'Initiatives',
              _statistics['initiatives']?.toString() ?? '0',
              Icons.lightbulb_outline,
              MiskTheme.miskLightGreen,
            ),
            _buildStatCard(
              'Tasks',
              _statistics['tasks']?.toString() ?? '0',
              Icons.task_outlined,
              MiskTheme.miskGold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: MiskTheme.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(MiskTheme.spacingMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: MiskTheme.spacingSmall),
            _isLoadingStats
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MiskTheme.miskTextDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'title': 'Members', 'icon': Icons.people_outline, 'route': '/members'},
      {'title': 'Events', 'icon': Icons.event_outlined, 'route': '/events'},
      {'title': 'Initiatives', 'icon': Icons.lightbulb_outline, 'route': '/initiatives'},
      {'title': 'Tasks', 'icon': Icons.task_outlined, 'route': '/tasks'},
      {'title': 'Finance', 'icon': Icons.monetization_on_outlined, 'route': '/finance'},
      {'title': 'Settings', 'icon': Icons.settings_outlined, 'route': '/settings'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: MiskTheme.miskDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MiskTheme.spacingMedium),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: MiskTheme.spacingMedium,
          crossAxisSpacing: MiskTheme.spacingMedium,
          childAspectRatio: 0.9,
          children: actions.map((action) => _buildActionCard(action)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return Card(
      elevation: MiskTheme.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/members');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${action['title']} module coming soon!'),
              backgroundColor: MiskTheme.miskDarkGreen,
            ),
          );
        },
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(MiskTheme.spacingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action['icon'] as IconData,
                size: 32,
                color: MiskTheme.miskDarkGreen,
              ),
              const SizedBox(height: MiskTheme.spacingSmall),
              Text(
                action['title'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MiskTheme.miskTextDark,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: MiskTheme.miskDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MiskTheme.spacingMedium),
        Card(
          elevation: MiskTheme.elevationMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: Column(
              children: [
                _buildActivityItem(
                  'Welcome to MISK Trust ERP!',
                  'Your account has been successfully set up.',
                  Icons.celebration_outlined,
                  'Just now',
                ),
                const Divider(),
                _buildActivityItem(
                  'System Status',
                  'All systems are operational and running smoothly.',
                  Icons.check_circle_outline,
                  '5 minutes ago',
                ),
                const Divider(),
                _buildActivityItem(
                  'Next Steps',
                  'Explore the modules to get started with managing trust operations.',
                  Icons.arrow_forward_outlined,
                  '10 minutes ago',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, IconData icon, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiskTheme.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MiskTheme.miskGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(MiskTheme.borderRadiusSmall),
            ),
            child: Icon(
              icon,
              size: 20,
              color: MiskTheme.miskGold,
            ),
          ),
          const SizedBox(width: MiskTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: MiskTheme.spacingXSmall),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MiskTheme.miskTextDark.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: MiskTheme.spacingXSmall),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MiskTheme.miskLightGreen,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}