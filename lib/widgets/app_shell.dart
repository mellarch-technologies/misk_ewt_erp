import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard_screen.dart';
import '../screens/initiatives/initiatives_list_screen.dart';
import '../screens/campaigns/campaigns_list_screen.dart';
import '../screens/donations/donations_unified_screen.dart';
import '../screens/settings/global_settings_screen.dart';
import '../screens/tasks/tasks_list_screen.dart';

class AppShell extends StatefulWidget {
  // Global access to current shell state for tab switching
  static final GlobalKey<_AppShellState> shellKey = GlobalKey<_AppShellState>();
  const AppShell({super.key});

  // Programmatically switch tabs
  static void goToTab(int index) => shellKey.currentState?._setIndex(index);
  static int? get currentTabIndex => shellKey.currentState?._index;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _pages = const <Widget>[
    DashboardScreen(),
    InitiativesListScreen(),
    CampaignsListScreen(),
    TasksListScreen(),
    DonationsUnifiedScreen(),
    GlobalSettingsScreen(),
  ];

  void _setIndex(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000; // tablet/desktop breakpoint
        final body = IndexedStack(index: _index, children: _pages);

        if (wide) {
          // NavigationRail on the left for wide screens
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => _setIndex(i),
                labelType: NavigationRailLabelType.all,
                leading: const SizedBox(height: 8),
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: Text('Initiatives')),
                  NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: Text('Campaigns')),
                  NavigationRailDestination(icon: Icon(Icons.task_outlined), selectedIcon: Icon(Icons.task), label: Text('Tasks')),
                  NavigationRailDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism), label: Text('Donations')),
                  NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
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
          );
        }

        // BottomNavigationBar on narrow screens
        return Scaffold(
          body: body,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: MiskTheme.miskGold,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Initiatives'),
              BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campaigns'),
              BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
              BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Donations'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
            onTap: (i) => _setIndex(i),
          ),
        );
      },
    );
  }
}
