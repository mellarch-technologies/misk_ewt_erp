import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/initiative_provider.dart';
import '../providers/campaign_provider.dart';
import '../providers/task_provider.dart';
import '../providers/event_announcement_provider.dart';
import '../providers/role_provider.dart';
import '../providers/permission_provider.dart';
import '../services/donation_service.dart';
import '../models/donation_model.dart';
import '../widgets/common_card.dart';
import '../widgets/initiative_card.dart';
import '../widgets/campaign_card.dart';
import '../widgets/dashboard_charts.dart';

class DashboardV2Screen extends StatefulWidget {
  const DashboardV2Screen({super.key});

  @override
  State<DashboardV2Screen> createState() => _DashboardV2ScreenState();
}

class _DashboardV2ScreenState extends State<DashboardV2Screen> {
  String? _selectedInitiativeId;
  String? _selectedCampaignId;
  double? _donationsChangePct;
  num _donationsConfirmed = 0;
  num _donationsReconciled = 0;
  List<Donation> _recentDonations = const [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final donationSvc = DonationService();
    final donations = await donationSvc.getDonationsOnce();
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
    setState(() {
      _donationsConfirmed = confirmed;
      _donationsReconciled = reconciled;
      _recentDonations = donations.take(10).toList();
      _donationsChangePct = donationsChangePct;
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>().users.length;
    final initiatives = context.watch<InitiativeProvider>().initiatives;
    final campaigns = context.watch<CampaignProvider>().campaigns;
    final tasks = context.watch<TaskProvider>().tasks;
    final roles = context.watch<RoleProvider>().roles.length;
    final events = context.watch<EventAnnouncementProvider>().events;
    final canEvents = context.watch<PermissionProvider>().can('can_manage_events');
    final now = DateTime.now();
    final upcomingEvents = events.where((e) {
      final dt = e.eventDate?.toDate();
      return e.type == 'event' && dt != null && !dt.isBefore(now);
    }).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Dashboard v2 (Labs)'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MiskTheme.primaryGreen, MiskTheme.darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpiCard('Members', users.toString(), Icons.people_alt, MiskTheme.memberPurple),
                  _kpiCard('Roles', roles.toString(), Icons.admin_panel_settings, MiskTheme.darkBlue),
                  _kpiCard('Initiatives', initiatives.length.toString(), Icons.flag, MiskTheme.primaryGreen),
                  _kpiCard('Campaigns', campaigns.length.toString(), Icons.campaign, MiskTheme.eventBlue),
                  _kpiCard('Donations', '${_donationsConfirmed} (${_donationsReconciled} rec)', Icons.volunteer_activism, MiskTheme.donationGreen, badge: _trendBadge(_donationsChangePct, MiskTheme.donationGreen)),
                  _kpiCard('Upcoming Events', upcomingEvents.toString(), Icons.event, MiskTheme.darkBlue),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedInitiativeId,
                      items: initiatives.map((i) => DropdownMenuItem(value: i.id, child: Text(i.title))).toList(),
                      onChanged: (v) => setState(() {
                        _selectedInitiativeId = v;
                        _selectedCampaignId = null;
                      }),
                      decoration: const InputDecoration(labelText: 'Initiative'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedCampaignId,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All campaigns')),
                        ...campaigns.where((c) => c.initiative?.id == _selectedInitiativeId).map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name)))
                      ],
                      onChanged: (v) => setState(() => _selectedCampaignId = v),
                      decoration: const InputDecoration(labelText: 'Campaign'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Featured Initiatives', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: initiatives.where((i) => i.featured == true).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final it = initiatives.where((i) => i.featured == true).toList()[index];
                  return SizedBox(
                    width: 360,
                    child: InitiativeCard(initiative: it, compact: true),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Featured Campaigns', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: campaigns.where((c) => c.featured == true).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final c = campaigns.where((c) => c.featured == true).toList()[index];
                  return SizedBox(
                    width: 360,
                    child: CampaignCard(campaign: c, compact: true),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Recent Donations', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _recentDonations.length) return null;
                final d = _recentDonations[index];
                final amount = d.amount;
                final status = d.status;
                final reconciled = d.bankReconciled == true ? 'Reconciled' : 'Pending';
                return ListTile(
                  leading: Icon(Icons.volunteer_activism, color: MiskTheme.donationGreen),
                  title: Text('Donation ₹$amount'),
                  subtitle: Text('Status: $status • $reconciled'),
                );
              },
              childCount: _recentDonations.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, {Widget? badge}) {
    return CommonCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  badge,
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _trendBadge(double? pct, Color base) {
    if (pct == null) return const SizedBox.shrink();
    Color c;
    IconData ic;
    String label;
    if (pct > 0.5) {
      c = Colors.green;
      ic = Icons.arrow_upward;
      label = '+${pct.toStringAsFixed(0)}%';
    } else if (pct < -0.5) {
      c = Colors.redAccent;
      ic = Icons.arrow_downward;
      label = '${pct.toStringAsFixed(0)}%';
    } else {
      c = Colors.white70;
      ic = Icons.remove;
      label = 'Stable';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

