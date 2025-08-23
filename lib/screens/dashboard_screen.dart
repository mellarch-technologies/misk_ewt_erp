import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../providers/initiative_provider.dart';
import '../providers/campaign_provider.dart';
import '../providers/task_provider.dart';
import '../providers/event_announcement_provider.dart';
import '../services/donation_service.dart';
import '../models/donation_model.dart';
import '../services/currency_helper.dart';
import '../widgets/app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.inShell = false});
  final bool inShell;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  String _userRole = 'Member'; // Default role
  String _userName = 'User';
  String _userDesignation = '';
  Future<void>? _dataFuture;

  // Donations KPI state
  num _donationsConfirmed = 0;
  num _donationsReconciled = 0;
  List<Donation> _recentDonations = const [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _dataFuture = _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final users = context.read<UserProvider>();
      final initiatives = context.read<InitiativeProvider>();
      final campaigns = context.read<CampaignProvider>();
      final tasks = context.read<TaskProvider>();
      final events = context.read<EventAnnouncementProvider>();
      final donationSvc = DonationService();

      final donationsFut = donationSvc.getDonationsOnce();

      await Future.wait([
        users.fetchUsers(),
        initiatives.fetchInitiatives(),
        campaigns.fetchCampaigns(),
        tasks.fetchTasks(),
        events.fetchEvents(),
        donationsFut,
      ]);

      final donations = await donationsFut;
      num confirmed = 0;
      num reconciled = 0;
      for (final d in donations) {
        if (d.status.toLowerCase() == 'confirmed') {
          confirmed += d.amount;
          if (d.bankReconciled == true) reconciled += d.amount;
        }
      }
      if (mounted) {
        setState(() {
          _donationsConfirmed = confirmed;
          _donationsReconciled = reconciled;
          _recentDonations = donations.take(10).toList();
        });
      }
    } catch (_) {
      // ignore errors; UI will handle empties gracefully
    }
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
    final content = FutureBuilder<void>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildKpiSection(context),
              const SizedBox(height: 24),
              const _MyTasksSection(),
              const SizedBox(height: 24),
              _buildRecentActivitiesSection(context),
            ],
          ),
        );
      },
    );

    if (widget.inShell) {
      // Render without own Scaffold/AppBar inside AppShell
      return content;
    }

    // Standalone fallback with simple title bar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (_userRole == 'Trustee' || _userRole == 'Admin')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
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
      body: content,
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Sabahal Khair';
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) greeting = 'Good Afternoon';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MiskTheme.primaryGreen,
            MiskTheme.darkBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
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
              color: const Color.fromRGBO(255, 255, 255, 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'May Allah bless your efforts in serving the community',
            style: TextStyle(
              fontSize: 14,
              color: const Color.fromRGBO(255, 255, 255, 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(BuildContext context) {
    final users = context.watch<UserProvider>().users.length;
    final initiatives = context.watch<InitiativeProvider>().initiatives.length;
    final campaigns = context.watch<CampaignProvider>().campaigns.length;
    final allTasks = context.watch<TaskProvider>().tasks;
    final openTasks = allTasks.where((t) {
      final s = t.status.toLowerCase();
      return !(s == 'done' || s == 'completed');
    }).length;

    final events = context.watch<EventAnnouncementProvider>().events;
    final now = DateTime.now();
    final upcomingEvents = events.where((e) {
      final dt = e.eventDate?.toDate();
      return e.type == 'event' && dt != null && !dt.isBefore(now);
    }).length;

    final donationsText = '${CurrencyHelper.formatInr(_donationsConfirmed)} (${CurrencyHelper.formatInr(_donationsReconciled)} rec)';

    Widget card(String title, String value, IconData icon, Color color) {
      return Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.85)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(icon, color: Colors.white, size: 28),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      // Force two columns on typical screens; fallback to one on ultra-narrow
      final crossAxisCount = c.maxWidth < 420 ? 1 : 2;
      final items = <Widget>[
        card('Members', users.toString(), Icons.people_alt, MiskTheme.memberPurple),
        card('Initiatives', initiatives.toString(), Icons.flag, MiskTheme.primaryGreen),
        card('Campaigns', campaigns.toString(), Icons.campaign, MiskTheme.eventBlue),
        card('Open Tasks', openTasks.toString(), Icons.task_alt, MiskTheme.accentGold),
        card('Upcoming Events', upcomingEvents.toString(), Icons.event, MiskTheme.darkBlue),
        card('Donations', donationsText, Icons.volunteer_activism, MiskTheme.donationGreen),
      ];
      return GridView.count(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: items,
      );
    });
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    final provider = context.watch<EventAnnouncementProvider>();
    final events = [...provider.events];
    events.sort((a, b) {
      final da = (a.eventDate ?? a.updatedAt ?? a.createdAt)?.toDate();
      final db = (b.eventDate ?? b.updatedAt ?? b.createdAt)?.toDate();
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    // Recent tasks by updatedAt/dueDate
    final tasks = [...context.watch<TaskProvider>().tasks];
    tasks.sort((a, b) {
      final da = (a.updatedAt ?? a.dueDate ?? a.createdAt)?.toDate();
      final db = (b.updatedAt ?? b.dueDate ?? b.createdAt)?.toDate();
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    // Recent donations by receivedAt/createdAt
    final donations = [..._recentDonations];
    donations.sort((a, b) {
      final da = (a.receivedAt ?? a.createdAt)?.toDate();
      final db = (b.receivedAt ?? b.createdAt)?.toDate();
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    // Build unified list
    final items = <_ActivityItem>[];
    for (final e in events.take(6)) {
      final when = (e.eventDate ?? e.updatedAt ?? e.createdAt)?.toDate();
      items.add(_ActivityItem(
        when: when,
        title: e.title,
        subtitle: e.type == 'event' ? 'Event' : 'Announcement',
        icon: e.type == 'event' ? Icons.event : Icons.campaign,
        color: e.type == 'event' ? MiskTheme.eventBlue : MiskTheme.accentGold,
      ));
    }
    for (final d in donations.take(6)) {
      final when = (d.receivedAt ?? d.createdAt)?.toDate();
      final amount = CurrencyHelper.formatInr(d.amount);
      final status = d.status.toLowerCase();
      final reconciled = d.bankReconciled == true ? ' • Reconciled' : '';
      items.add(_ActivityItem(
        when: when,
        title: 'Donation $amount',
        subtitle: 'Status: $status$reconciled',
        icon: Icons.volunteer_activism,
        color: MiskTheme.donationGreen,
      ));
    }
    for (final t in tasks.take(6)) {
      final when = (t.updatedAt ?? t.dueDate ?? t.createdAt)?.toDate();
      items.add(_ActivityItem(
        when: when,
        title: t.title,
        subtitle: 'Task • ${t.status}',
        icon: Icons.task_alt,
        color: MiskTheme.accentGold,
      ));
    }

    // Sort unified by date desc and take top 8
    items.sort((a, b) {
      final da = a.when;
      final db = b.when;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    final recent = items.take(8).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final isGrid = c.maxWidth >= 700; // two-column cards on wider screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/events_announcements'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Text('No recent activities.', style: TextStyle(color: Colors.black54))
            else if (!isGrid)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _activityTile(recent[i]),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.5,
                ),
                itemCount: recent.length,
                itemBuilder: (context, i) => _activityTile(recent[i]),
              ),
          ],
        );
      },
    );
  }

  Widget _activityTile(_ActivityItem it) {
    final when = it.when;
    final whenText = when == null ? '' : '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: it.color,
          child: Icon(it.icon, color: Colors.white),
        ),
        title: Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text([it.subtitle, whenText].where((e) => e.isNotEmpty).join(' • ')),
      ),
    );
  }
}

class _MyTasksSection extends StatelessWidget {
  const _MyTasksSection();
  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUser = context.read<UserProvider>().getCurrentUserByEmail(authUser?.email);
    final tasks = context.watch<TaskProvider>().tasks;
    final my = currentUser == null
        ? []
        : tasks.where((t) => t.assignedTo?.id == currentUser.uid).toList();

    my.sort((a, b) {
      final da = a.dueDate?.toDate();
      final db = b.dueDate?.toDate();
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    final mine = my.take(6).toList();

    Color statusColor(String s) {
      s = s.toLowerCase();
      if (s == 'done' || s == 'completed') return MiskTheme.successGreen;
      if (s == 'in-progress' || s == 'ongoing') return MiskTheme.eventBlue;
      return MiskTheme.warningOrange;
    }

    return LayoutBuilder(
      builder: (context, c) {
        final isGrid = c.maxWidth >= 700; // two columns on wider screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => AppShell.goToTab(AppShell.tabTasks),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (mine.isEmpty)
              const Text('No tasks assigned to you.', style: TextStyle(color: Colors.black54))
            else if (!isGrid)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mine.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = mine[i];
                  final due = t.dueDate?.toDate();
                  final dueText = due == null ? 'No due date' : '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(Icons.task_alt, color: statusColor(t.status)),
                      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Due: $dueText'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor(t.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t.status,
                          style: TextStyle(color: statusColor(t.status), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.5,
                ),
                itemCount: mine.length,
                itemBuilder: (context, i) {
                  final t = mine[i];
                  final due = t.dueDate?.toDate();
                  final dueText = due == null ? 'No due date' : '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(Icons.task_alt, color: statusColor(t.status)),
                      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Due: $dueText'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor(t.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t.status,
                          style: TextStyle(color: statusColor(t.status), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _ActivityItem {
  final DateTime? when;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  _ActivityItem({required this.when, required this.title, required this.subtitle, required this.icon, required this.color});
}
