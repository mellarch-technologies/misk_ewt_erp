import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard_screen.dart';
import '../screens/initiatives/initiatives_list_screen.dart';
import '../screens/campaigns/campaigns_list_screen.dart';
import '../screens/donations/donations_unified_screen.dart';
import '../screens/settings/global_settings_screen.dart';
import '../screens/tasks/tasks_list_screen.dart';
import '../screens/users/users_list_screen.dart';
import '../providers/app_auth_provider.dart';
import '../providers/permission_provider.dart';
import '../screens/events_announcements/events_announcements_list_screen.dart';

class AppShell extends StatefulWidget {
  // Global access to current shell state for tab switching
  static final GlobalKey<_AppShellState> shellKey = GlobalKey<_AppShellState>();
  const AppShell({super.key});

  // Programmatically switch tabs
  static void goToTab(int index) => shellKey.currentState?._setIndex(index);
  static int? get currentTabIndex => shellKey.currentState?._index;

  // Stable tab indices for cross-file references
  static const int tabDashboard = 0;
  static const int tabUsers = 1;
  static const int tabInitiatives = 2;
  static const int tabCampaigns = 3;
  static const int tabTasks = 4;
  static const int tabDonations = 5;
  static const int tabSettings = 6;
  static const int tabEvents = 7; // appended to avoid shifting saved indices

  @override
  State<AppShell> createState() => _AppShellState();
}

class _NavItem {
  final int pageIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? permissionKey; // null means always visible
  const _NavItem({
    required this.pageIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.permissionKey,
  });
}

class _MoreNavItem extends _NavItem {
  const _MoreNavItem()
      : super(pageIndex: -1, icon: Icons.more_horiz, selectedIcon: Icons.more_horiz, label: 'More');
}

class _AppShellState extends State<AppShell> {
  static const _prefsKeyLastTab = 'last_tab_index';
  int _index = 0;
  SharedPreferences? _prefs;

  late final List<Widget> _pages = <Widget>[
    const DashboardScreen(inShell: true),
    const UsersListScreen(inShell: true),
    const InitiativesListScreen(inShell: true),
    const CampaignsListScreen(inShell: true),
    const TasksListScreen(inShell: true),
    const DonationsUnifiedScreen(inShell: true),
    const GlobalSettingsScreen(inShell: true),
    const EventsAnnouncementsListScreen(inShell: true), // appended
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getInt(_prefsKeyLastTab);
    if (saved != null && saved >= 0 && saved < _pages.length) {
      setState(() => _index = saved);
    }
  }

  void _setIndex(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    // Persist selection
    _prefs?.setInt(_prefsKeyLastTab, i);
  }

  Widget _buildAppBarActions(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;

    final String? photoUrl = user?.photoURL;
    // initials computed but we won't display raw letter anymore
    final String initials = () {
      final name = user?.displayName ?? user?.email ?? 'U';
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return (parts.first.isNotEmpty ? parts.first[0] : '') + (parts.last.isNotEmpty ? parts.last[0] : '');
      }
      return name.isNotEmpty ? name[0].toUpperCase() : 'U';
    }();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon')),
            );
          },
          icon: const Icon(Icons.notifications_outlined),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'Account',
          position: PopupMenuPosition.under,
          onSelected: (val) async {
            switch (val) {
              // Removed 'profile' temporary redirect to settings per request
              case 'logout':
                await context.read<AppAuthProvider>().logout();
                break;
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Logout'))),
          ],
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? const Icon(Icons.person_outline, size: 18, color: Colors.black54)
                : null,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Define all possible nav items with optional permission keys
  static const List<_NavItem> _allNavItems = [
    _NavItem(pageIndex: AppShell.tabDashboard, icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(pageIndex: AppShell.tabUsers, icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt, label: 'Users', permissionKey: 'can_manage_users'),
    _NavItem(pageIndex: AppShell.tabInitiatives, icon: Icons.flag_outlined, selectedIcon: Icons.flag, label: 'Initiatives'),
    _NavItem(pageIndex: AppShell.tabCampaigns, icon: Icons.campaign_outlined, selectedIcon: Icons.campaign, label: 'Campaigns'),
    _NavItem(pageIndex: AppShell.tabTasks, icon: Icons.task_outlined, selectedIcon: Icons.task, label: 'Tasks'),
    _NavItem(pageIndex: AppShell.tabEvents, icon: Icons.event_outlined, selectedIcon: Icons.event, label: 'Events & Announcements', permissionKey: 'can_manage_events'),
    _NavItem(pageIndex: AppShell.tabDonations, icon: Icons.volunteer_activism_outlined, selectedIcon: Icons.volunteer_activism, label: 'Donations'),
    _NavItem(pageIndex: AppShell.tabSettings, icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
  ];

  // Helper to compute visible nav items based on permissions
  List<_NavItem> _visibleNavItems(PermissionProvider perm) {
    // While permissions are loading, show all items to avoid flicker
    if (perm.isLoading) return _allNavItems;
    return _allNavItems.where((item) {
      if (item.permissionKey == null) return true;
      return perm.can(item.permissionKey!);
    }).toList(growable: false);
  }

  List<_NavItem> _bottomPrimaryItems(List<_NavItem> visible) {
    // Desired order: Dashboard, Tasks, Initiatives, Campaigns, Donations, Settings
    const desiredOrder = [
      AppShell.tabDashboard,
      AppShell.tabTasks,
      AppShell.tabInitiatives,
      AppShell.tabCampaigns,
      AppShell.tabDonations,
      AppShell.tabSettings,
    ];
    final byIndex = {for (var n in visible) n.pageIndex: n};
    final items = <_NavItem>[];
    for (final idx in desiredOrder) {
      final n = byIndex[idx];
      if (n != null) items.add(n);
    }
    // Cap at 5; if all 6 are present, Settings will remain in Drawer
    if (items.length > 5) {
      return items.sublist(0, 5);
    }
    return items;
  }

  String _shortLabel(String label) {
    // Simple heuristic: keep concise names for bottom nav; truncate with ellipsis if very long
    if (label.length > 12) {
      return '${label.substring(0, 11)}…';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final perm = context.watch<PermissionProvider>();
    final visible = _visibleNavItems(perm);

    // Ensure current index is valid/visible; if not, switch to first visible
    final selectedVisibleIndex = visible.indexWhere((n) => n.pageIndex == _index);
    if (selectedVisibleIndex == -1 && visible.isNotEmpty) {
      // Defer changing index until after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _setIndex(visible.first.pageIndex);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800; // tablet/desktop breakpoint
        final body = IndexedStack(index: _index, children: _pages);

        if (wide) {
          // Wide layout: Scaffold with top AppBar and permanent left rail
          return Scaffold(
            appBar: AppBar(
              // Removed logo from AppBar per request
              title: const Text('MISK Mini ERP'),
              actions: [
                _buildAppBarActions(context),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedVisibleIndex == -1 ? 0 : selectedVisibleIndex,
                  onDestinationSelected: (i) => _setIndex(visible[i].pageIndex),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.asset('assets/misk_logo.png', height: 56),
                  ),
                  destinations: [
                    for (final n in visible)
                      NavigationRailDestination(icon: Icon(n.icon), selectedIcon: Icon(n.selectedIcon), label: Text(n.label)),
                  ],
                ),
                // Fancy divider: subtle gold line with soft shadow
                Container(
                  width: 14,
                  decoration: const BoxDecoration(
                    boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(1, 0))],
                  ),
                  child: Center(
                    child: Container(
                      width: 2,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            MiskTheme.miskGold,
                            MiskTheme.miskGold.withAlpha(200),
                            MiskTheme.miskGold,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          );
        }

        // Narrow layout: Drawer + top AppBar + bottom NavigationBar for primaries
        final bottomItems = _bottomPrimaryItems(visible);
        final bottomIndex = bottomItems.indexWhere((n) => n.pageIndex == _index);

        return Scaffold(
          appBar: AppBar(
            // Removed logo from AppBar per request
            title: const Text('MISK Mini ERP'),
            actions: [
              _buildAppBarActions(context),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: MiskTheme.miskGold),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/misk_logo.png', height: 56),
                      const SizedBox(height: 8),
                      const Text('MISK Mini ERP', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ),
                // Core section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Core', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                ),
                for (final n in visible.where((n) => n.pageIndex == AppShell.tabDashboard || n.pageIndex == AppShell.tabUsers))
                  ListTile(
                    leading: Icon(n.selectedIcon),
                    title: Text(n.label),
                    selected: _index == n.pageIndex,
                    onTap: () { _setIndex(n.pageIndex); Navigator.pop(context); },
                  ),
                const Divider(height: 0),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Operations', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                ),
                for (final n in visible.where((n) => n.pageIndex == AppShell.tabInitiatives || n.pageIndex == AppShell.tabCampaigns || n.pageIndex == AppShell.tabTasks || n.pageIndex == AppShell.tabDonations || n.pageIndex == AppShell.tabEvents))
                  ListTile(
                    leading: Icon(n.selectedIcon),
                    title: Text(n.label),
                    selected: _index == n.pageIndex,
                    onTap: () { _setIndex(n.pageIndex); Navigator.pop(context); },
                  ),
                const Divider(height: 0),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Settings', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                ),
                for (final n in visible.where((n) => n.pageIndex == AppShell.tabSettings))
                  ListTile(
                    leading: Icon(n.selectedIcon),
                    title: Text(n.label),
                    selected: _index == n.pageIndex,
                    onTap: () { _setIndex(n.pageIndex); Navigator.pop(context); },
                  ),
              ],
            ),
          ),
          body: body,
          bottomNavigationBar: bottomItems.isEmpty
              ? null
              : NavigationBar(
                  selectedIndex: bottomIndex == -1 ? 0 : bottomIndex,
                  onDestinationSelected: (i) {
                    final sel = bottomItems[i];
                    _setIndex(sel.pageIndex);
                  },
                  destinations: [
                    for (final n in bottomItems)
                      NavigationDestination(icon: Icon(n.icon), selectedIcon: Icon(n.selectedIcon), label: _shortLabel(n.label)),
                  ],
                ),
        );
      },
    );
  }
}
