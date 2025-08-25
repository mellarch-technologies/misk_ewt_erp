// filepath: lib/screens/dashboard_screen_legacy.dart
// Backup of DashboardScreen as of 2025-08-24. Kept for reference and rollback.
// Note: Class names changed to avoid conflicts.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../providers/initiative_provider.dart';
import '../providers/campaign_provider.dart';
import '../providers/task_provider.dart';
import '../providers/event_announcement_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/role_provider.dart';
import '../services/donation_service.dart';
import '../models/donation_model.dart';
import '../services/currency_helper.dart';
import '../widgets/app_shell.dart';
import '../widgets/state_views.dart';
import '../widgets/initiative_card.dart';
import '../widgets/campaign_card.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/common_card.dart';

class DashboardScreenLegacy extends StatefulWidget {
  const DashboardScreenLegacy({super.key, this.inShell = false});
  final bool inShell;

  @override
  State<DashboardScreenLegacy> createState() => _DashboardScreenLegacyState();
}

class _DashboardScreenLegacyState extends State<DashboardScreenLegacy> {
  final AuthService _authService = AuthService();
  String _userRole = 'Member';
  String _userName = 'User';
  Future<void>? _dataFuture;

  num _donationsConfirmed = 0;
  num _donationsReconciled = 0;
  List<Donation> _recentDonations = const [];
  double? _donationsChangePct;

  String? _masjidInitiativeId;
  num _masjidGoal = 0;
  num _masjidConfirmed = 0;
  num _masjidReconciled = 0;
  List<DateTime> _trendX = const [];
  List<double> _trendY = const [];
  Map<String, int> _masjidTaskCounts = const {};

  String? _selectedInitiativeId;
  String? _selectedCampaignId;

  static const _prefsInitKey = 'selected_initiative_id';
  static const _prefsCampKey = 'selected_campaign_id';

  @override
  void initState() {
    super.initState();
    _loadPersistedSelection();
    _loadUserInfo();
    _dataFuture = _loadDashboardData();
  }

  Future<void> _loadPersistedSelection() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedInitiativeId = prefs.getString(_prefsInitKey);
      _selectedCampaignId = prefs.getString(_prefsCampKey);
    });
  }

  Future<void> _persistSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsInitKey, _selectedInitiativeId ?? '');
    await prefs.setString(_prefsCampKey, _selectedCampaignId ?? '');
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
      final now = DateTime.now();
      num last7 = 0;
      num prev7 = 0;
      for (final d in donations) {
        if (d.status.toLowerCase() == 'confirmed') {
          confirmed += d.amount;
          if (d.bankReconciled == true) reconciled += d.amount;
          final when = (d.receivedAt ?? d.createdAt)?.toDate();
          if (when != null) {
            final diff = now.difference(when).inDays;
            if (diff < 7) {
              last7 += d.amount;
            } else if (diff < 14) {
              prev7 += d.amount;
            }
          }
        }
      }
      double? donationsChangePct;
      if (prev7 == 0) {
        donationsChangePct = last7 > 0 ? 100.0 : 0.0;
      } else {
        donationsChangePct = ((last7 - prev7) / prev7) * 100.0;
      }

      final allInitiatives = initiatives.initiatives;
      String? defaultInitId;
      if (allInitiatives.isNotEmpty) {
        final found = allInitiatives.firstWhere(
          (i) => i.title.toLowerCase().contains('masjid'),
          orElse: () => allInitiatives.first,
        );
        defaultInitId = found.id;
      }
      _selectedInitiativeId ??= defaultInitId;

      await _recomputeScopedKpis();

      if (mounted) {
        setState(() {
          _donationsConfirmed = confirmed;
          _donationsReconciled = reconciled;
          _recentDonations = donations.take(10).toList();
          _donationsChangePct = donationsChangePct;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _recomputeScopedKpis() async {
    final initiatives = context.read<InitiativeProvider>();
    final campaigns = context.read<CampaignProvider>();
    final donationSvc = DonationService();

    String? initId = _selectedInitiativeId;
    String? campId = _selectedCampaignId;

    if (initId == null && initiatives.initiatives.isNotEmpty) {
      initId = initiatives.initiatives.first.id;
    }

    if (initId == null) return;

    final initRef = FirebaseFirestore.instance.collection('initiatives').doc(initId);

    final initDonations = await donationSvc.getDonationsOnce(initiative: initRef);
    final filtered = campId == null
        ? initDonations
        : initDonations.where((d) => d.campaign?.id == campId).toList();

    final now = DateTime.now();
    final buckets = <DateTime, double>{};
    for (int w = 7; w >= 0; w--) {
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1))
          .subtract(Duration(days: 7 * w));
      buckets[monday] = 0.0;
    }
    num confirmedSum = 0;
    num reconciledSum = 0;
    for (final d in filtered) {
      final when = (d.receivedAt ?? d.createdAt)?.toDate();
      if (when == null) continue;
      if (d.status.toLowerCase() == 'confirmed') {
        DateTime? key;
        for (final k in buckets.keys) {
          if (!when.isBefore(k)) {
            key = k;
          } else {
            break;
          }
        }
        key ??= buckets.keys.first;
        buckets[key] = (buckets[key] ?? 0) + d.amount.toDouble();
        confirmedSum += d.amount;
        if (d.bankReconciled == true) reconciledSum += d.amount;
      }
    }
    final trendX = buckets.keys.toList()..sort();
    final trendY = trendX.map((k) => (buckets[k] ?? 0).toDouble()).toList();

    final byCampaign = {for (final c in campaigns.campaigns) c.id: c.initiative};
    final allTasks = context.read<TaskProvider>().tasks;
    final counts = <String, int>{};
    for (final t in allTasks) {
      final matchesInit = t.initiative?.id == initRef.id ||
          (t.campaign != null && (byCampaign[t.campaign!.id]?.id == initRef.id));
      final matchesCamp = campId == null || t.campaign?.id == campId;
      if (matchesInit && matchesCamp) {
        counts[t.status] = (counts[t.status] ?? 0) + 1;
      }
    }

    if (mounted) {
      setState(() {
        _masjidInitiativeId = initId;
        _masjidGoal = (initiatives.initiatives.firstWhere((i) => i.id == initId).goalAmount ?? 0);
        _masjidConfirmed = confirmedSum;
        _masjidReconciled = reconciledSum;
        _trendX = trendX;
        _trendY = trendY;
        _masjidTaskCounts = counts;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        _userRole = 'Trustee';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Legacy backup placeholder UI; not used in app navigation
    return const SizedBox.shrink();
  }
}
