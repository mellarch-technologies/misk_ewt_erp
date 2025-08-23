# Session Log — Left Nav Restoration & Dashboard Fixes (2025-08-23)

Context
- Goal: Restore Left Nav (with Users), fix Dashboard layout/order and RenderFlex overflows, align with prior plan and Perplexity review.
- Repo paths of interest: lib/widgets/app_shell.dart, lib/screens/dashboard_screen.dart, project_log.md, chat_scripts/perplexity_github_branches_review_23rd_aug_2025.

Decisions
- Keep persistent Left Nav on wide screens (NavigationRail) and Drawer on mobile; remove bottom nav to reduce complexity/overflows.
- Dashboard welcome message stays in header card; AppBar shows page title only.
- Dashboard order: KPIs → My Tasks → Recent Activities. My Tasks and Recent Activities use 2-card columns on wider screens.
- Add Users to Left Nav and expose stable AppShell tab indices for safe cross-screen navigation.

Changes Applied
- app_shell.dart
  - Added Users tab/page and dynamic AppBar title.
  - Wide: Scaffold with NavigationRail + gold divider; Narrow: Drawer with same items (Dashboard, Users, Initiatives, Campaigns, Tasks, Donations, Settings).
  - Exposed constants: tabDashboard, tabUsers, tabInitiatives, tabCampaigns, tabTasks, tabDonations, tabSettings.
- dashboard_screen.dart
  - Added inShell flag to render without its own AppBar when inside AppShell.
  - Moved greeting to header card; kept AppBar title minimal when standalone.
  - Implemented two-column layouts for My Tasks and Recent Activities when width ≥ 700px; ensured shrinkWrap + disabled nested scrolling to prevent RenderFlex overflow.
  - Replaced magic index in "View all" with AppShell.tabTasks.
- project_log.md
  - Appended dated entry summarizing the above and added a fresh consolidated TODO list derived from the Perplexity review.

Result
- Left Nav (with Users) restored; App bar shows page name. Dashboard sections ordered and responsive with no overflow during scroll.

Fresh TODO Plan (derived from Perplexity review + repo state)
1) Codebase hygiene
- Consolidate/remove legacy lib versions; remove duplicate pubspec copies; normalize imports.
2) Tests
- Unit tests for core providers; widget tests for AppShell/Dashboard; integration test: login → dashboard.
3) Performance
- Pagination for large lists; Firestore caching; optimize images.
4) UI/UX standardization
- Roll CommonCard/MiskBadge/FilterBar everywhere; loading skeletons; tablet/desktop polish; accessibility labels/contrast.
5) Dashboard enhancements
- KPI deltas/trends; mini charts; role-based widgets.
6) Features
- Bulk user ops (CSV); global search; donation reconciliation polish.
7) Docs/Ops
- README setup; service API docs; module guides; deployment runbooks.

Next Steps
- Run a full build and manual smoke on devices (mobile/tablet/web) to validate rail/drawer behavior and responsive grids.
- Start code consolidation and test scaffolding.

Author: GitHub Copilot

