// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/role_provider.dart';
import '../providers/initiative_provider.dart';
import '../providers/campaign_provider.dart';
import '../providers/task_provider.dart';
import '../providers/event_announcement_provider.dart';
import '../services/donation_service.dart';
import '../models/initiative_model.dart';
import '../models/donation_model.dart';
import '../providers/permission_provider.dart';
import '../providers/app_auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.inShell = false});
  final bool inShell;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Scoped KPI state
  String? _selectedInitiativeId;
  String? _selectedCampaignId;
  bool _kpiBusy = false;
  num _scopedGoal = 0;
  num _scopedConfirmed = 0;
  num _scopedReconciled = 0;
  Donation? _latestDonation;
  // Latest (global) donation
  Donation? _latestGlobalDonation;
  bool _latestGlobalBusy = false;
  // Recent activities (donations loaded here; events from provider)
  List<Donation> _recentDonations = const [];
  bool _recentBusy = false;

  static const _prefsInitKey = 'selected_initiative_id';
  static const _prefsCampKey = 'selected_campaign_id';

  @override
  void initState() {
    super.initState();
    _loadPersistedScope();
    _loadLatestGlobalDonation();
    _loadRecentDonations();
  }

  Future<void> _loadPersistedScope() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final init = prefs.getString(_prefsInitKey);
      final camp = prefs.getString(_prefsCampKey);
      _selectedInitiativeId = (init != null && init.isNotEmpty) ? init : null;
      _selectedCampaignId = (camp != null && camp.isNotEmpty) ? camp : null;
    });
    await _computeScopedKpis();
  }

  Future<void> _persistScope() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsInitKey, _selectedInitiativeId ?? '');
    await prefs.setString(_prefsCampKey, _selectedCampaignId ?? '');
  }

  Future<void> _computeScopedKpis() async {
    if (!mounted) return;
    final initiatives = context.read<InitiativeProvider?>();
    // Removed unused variable 'campaigns'

    // Resolve goal from initiative
    num goal = 0;
    if (_selectedInitiativeId != null && initiatives != null) {
      final i = initiatives.initiatives.firstWhere(
        (x) => x.id == _selectedInitiativeId,
        orElse: () => Initiative(id: '', title: ''),
      );
      goal = i.goalAmount ?? 0;
    }

    setState(() {
      _kpiBusy = true;
      _scopedGoal = goal;
      _scopedConfirmed = 0;
      _scopedReconciled = 0;
      _latestDonation = null;
    });

    try {
      final donationSvc = DonationService();
      DocumentReference? initRef;
      DocumentReference? campRef;
      if (_selectedInitiativeId != null) {
        initRef = FirebaseFirestore.instance.collection('initiatives').doc(_selectedInitiativeId);
      }
      if (_selectedCampaignId != null) {
        campRef = FirebaseFirestore.instance.collection('campaigns').doc(_selectedCampaignId);
      }
      final items = await donationSvc.getDonationsOnce(initiative: initRef, campaignRef: campRef);
      num confirmed = 0;
      num reconciled = 0;
      Donation? latest;
      for (final d in items) {
        if (latest == null) latest = d;
        if (d.status.toLowerCase() == 'confirmed') {
          confirmed += d.amount;
          if (d.bankReconciled == true) reconciled += d.amount;
        }
      }
      if (!mounted) return;
      setState(() {
        _scopedConfirmed = confirmed;
        _scopedReconciled = reconciled;
        _latestDonation = latest;
      });
    } catch (_) {
      // keep defaults
    } finally {
      if (mounted) {
        setState(() {
          _kpiBusy = false;
        });
      }
    }
  }

  Future<void> _loadLatestGlobalDonation() async {
    setState(() => _latestGlobalBusy = true);
    try {
      final items = await DonationService().getDonationsOnce();
      setState(() {
        _latestGlobalDonation = items.isNotEmpty ? items.first : null;
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _latestGlobalBusy = false);
    }
  }

  Future<void> _loadRecentDonations() async {
    setState(() => _recentBusy = true);
    try {
      final items = await DonationService().getDonationsOnce();
      if (!mounted) return;
      setState(() {
        _recentDonations = items.take(10).toList();
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _recentBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider?>()?.users.length ?? 0;
    final roles = context.watch<RoleProvider?>()?.roles.length ?? 0;
    final initiativesCount = context.watch<InitiativeProvider?>()?.initiatives.length ?? 0;
    final campaignsCount = context.watch<CampaignProvider?>()?.campaigns.length ?? 0;
    final tasks = context.watch<TaskProvider?>()?.tasks.length ?? 0;
    final events = context.watch<EventAnnouncementProvider?>()?.events.length ?? 0;
    final permission = context.watch<PermissionProvider?>();
    final auth = context.watch<AppAuthProvider?>();
    final uid = auth?.user?.uid;
    final roleName = permission?.roleName ?? 'Guest';
    final isSuper = permission?.isSuperAdmin == true;
    final canViewAllTasks = isSuper || roleName.toLowerCase().contains('trustee') || roleName.toLowerCase().contains('admin');

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: MiskTheme.miskGold,
            child: const ListTile(
              title: Text('Welcome to MISK ERP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Quick overview and counts', style: TextStyle(color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpi('Users', users.toString(), Icons.people_alt),
              _kpi('Roles', roles.toString(), Icons.admin_panel_settings),
              _kpi('Initiatives', initiativesCount.toString(), Icons.flag),
              _kpi('Campaigns', campaignsCount.toString(), Icons.campaign),
              _kpi('Tasks', tasks.toString(), Icons.task_alt),
              _kpi('Events', events.toString(), Icons.event),
            ],
          ),
          const SizedBox(height: 16),
          _kpiScopeCard(context),
          const SizedBox(height: 16),
          _tasksSection(context, canViewAllTasks: canViewAllTasks, currentUid: uid),
          const SizedBox(height: 16),
          _latestDonationCard(),
          const SizedBox(height: 16),
          _upcomingEventsSection(context),
          const SizedBox(height: 16),
          _recentActivitiesSection(context),
        ],
      ),
    );

    if (widget.inShell) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: content,
    );
  }

  Widget _kpi(String label, String value, IconData icon) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: MiskTheme.miskGold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiScopeCard(BuildContext context) {
    final initiatives = context.watch<InitiativeProvider?>()?.initiatives ?? const <Initiative>[];
    final campaigns = context.watch<CampaignProvider?>()?.campaigns ?? const [];

    String initiativeLabel = 'Select Initiative';
    if (_selectedInitiativeId != null) {
      final found = initiatives.where((i) => i.id == _selectedInitiativeId).toList();
      if (found.isNotEmpty) initiativeLabel = found.first.title;
    }

    String campaignLabel = 'Select Campaign (optional)';
    if (_selectedCampaignId != null) {
      final found = campaigns.where((c) => c.id == _selectedCampaignId).toList();
      if (found.isNotEmpty) campaignLabel = found.first.name; // fix: Campaign.name
    }

    final pct = (_scopedGoal > 0) ? ((_scopedConfirmed.toDouble() / _scopedGoal.toDouble()).clamp(0.0, 1.0)) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KPIs (Scoped)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _scopeTile('Initiative', initiativeLabel, Icons.flag, onTap: initiatives.isEmpty ? null : _pickInitiative),
                _scopeTile('Campaign', campaignLabel, Icons.campaign, onTap: (_selectedInitiativeId == null) ? null : _pickCampaign),
                TextButton.icon(
                  onPressed: (_selectedInitiativeId != null || _selectedCampaignId != null)
                      ? () async {
                          setState(() {
                            _selectedInitiativeId = null;
                            _selectedCampaignId = null;
                          });
                          await _persistScope();
                          await _computeScopedKpis();
                        }
                      : null,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_kpiBusy)
              const LinearProgressIndicator(minHeight: 3)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _miniStat('Goal', _formatCurrency(_scopedGoal))),
                      const SizedBox(width: 12),
                      Expanded(child: _miniStat('Confirmed', _formatCurrency(_scopedConfirmed))),
                      const SizedBox(width: 12),
                      Expanded(child: _miniStat('Reconciled', _formatCurrency(_scopedReconciled))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.black12, color: MiskTheme.miskGold),
                  ),
                  const SizedBox(height: 8),
                  Text('Progress: ${(pct * 100).toStringAsFixed(1)}% of goal', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  if (_latestDonation != null)
                    Row(
                      children: [
                        const Icon(Icons.payments, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Latest Donation: ${_latestDonation!.donorName} • ${_latestDonation!.method} • ${_formatCurrency(_latestDonation!.amount)}',
                            style: const TextStyle(color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _scopeTile(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03), // replace withOpacity
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Text('$label: ', style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickInitiative() async {
    final initiatives = context.read<InitiativeProvider?>()?.initiatives ?? const <Initiative>[];
    if (initiatives.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String q = '';
        return StatefulBuilder(builder: (ctx, setM) {
          final items = q.isEmpty
              ? initiatives
              : initiatives.where((i) => i.title.toLowerCase().contains(q)).toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text('Select Initiative', style: TextStyle(fontWeight: FontWeight.w700)),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search initiatives'),
                      onChanged: (v) => setM(() => q = v.trim().toLowerCase()),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final i = items[idx];
                        return ListTile(
                          title: Text(i.title),
                          onTap: () => Navigator.of(ctx).pop(i.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    if (selected != null) {
      setState(() {
        _selectedInitiativeId = selected;
        _selectedCampaignId = null; // reset campaign when initiative changes
      });
      await _persistScope();
      await _computeScopedKpis();
    }
  }

  Future<void> _pickCampaign() async {
    if (_selectedInitiativeId == null) return;
    final cProvider = context.read<CampaignProvider?>();
    final all = cProvider?.campaigns ?? const [];
    final items = all.where((c) => c.initiative?.id == _selectedInitiativeId).toList();
    if (items.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String q = '';
        return StatefulBuilder(builder: (ctx, setM) {
          final filtered = q.isEmpty
              ? items
              : items.where((c) => c.name.toLowerCase().contains(q)).toList(); // fix: Campaign.name
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text('Select Campaign', style: TextStyle(fontWeight: FontWeight.w700)),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search campaigns'),
                      onChanged: (v) => setM(() => q = v.trim().toLowerCase()),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final c = filtered[idx];
                        return ListTile(
                          title: Text(c.name), // fix: Campaign.name
                          onTap: () => Navigator.of(ctx).pop(c.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    if (selected != null) {
      setState(() {
        _selectedCampaignId = selected;
      });
      await _persistScope();
      await _computeScopedKpis();
    }
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatCurrency(num v) {
    // Simple INR format; can be replaced with CurrencyHelper if needed
    return '₹${v.toStringAsFixed(0)}';
  }

  Widget _tasksSection(BuildContext context, {required bool canViewAllTasks, required String? currentUid}) {
    final tProv = context.watch<TaskProvider?>();
    final all = tProv?.tasks ?? const [];
    // Removed unused roleName
    bool myOnlyDefault = !canViewAllTasks; // non-admins default to my tasks

    // Local stateful toggle inside the card
    bool myOnly = myOnlyDefault;

    List<dynamic> _filter(List<dynamic> list) {
      if (!canViewAllTasks || myOnly) {
        if (currentUid == null) return const [];
        return list.where((t) => t.assignedTo?.id == currentUid).toList();
      }
      return list;
    }

    List<dynamic> _sorted(List<dynamic> list) {
      list.sort((a, b) {
        final ad = a.dueDate?.toDate();
        final bd = b.dueDate?.toDate();
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
      return list;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (ctx, setM) {
            final base = List.of(all);
            final items = _sorted(_filter(base)).take(5).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tasks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    if (canViewAllTasks)
                      Row(
                        children: [
                          const Text('My tasks only'),
                          const SizedBox(width: 8),
                          Switch(
                            value: myOnly,
                            onChanged: (v) => setM(() => myOnly = v),
                          ),
                        ],
                      )
                    else
                      Text('Showing my tasks', style: TextStyle(color: Colors.black54.withValues(alpha: 0.8))), // replace withOpacity
                  ],
                ),
                const SizedBox(height: 12),
                if ((tProv?.isBusy ?? false) && (tProv?.tasks.isEmpty ?? true))
                  const LinearProgressIndicator(minHeight: 2)
                else if (items.isEmpty)
                  const Text('No tasks to show', style: TextStyle(color: Colors.black54))
                else
                  ...items.map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(t.status, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              t.dueDate != null ? _formatDate(t.dueDate!.toDate()) : 'No due',
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _latestDonationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Latest Donation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (_latestGlobalBusy)
              const LinearProgressIndicator(minHeight: 2)
            else if (_latestGlobalDonation == null)
              const Text('No donations yet', style: TextStyle(color: Colors.black54))
            else
              Row(
                children: [
                  const Icon(Icons.payments, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_latestGlobalDonation!.donorName} • ${_latestGlobalDonation!.method} • ${_formatCurrency(_latestGlobalDonation!.amount)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(((_latestGlobalDonation!.receivedAt ?? _latestGlobalDonation!.createdAt)!.toDate())),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingEventsSection(BuildContext context) {
    final eProv = context.watch<EventAnnouncementProvider?>();
    final tProv = context.watch<TaskProvider?>();
    final now = DateTime.now();
    final events = (eProv?.events ?? const [])
        .where((e) => e.type == 'event' && e.eventDate != null && e.eventDate!.toDate().isAfter(now))
        .toList()
      ..sort((a, b) => a.eventDate!.toDate().compareTo(b.eventDate!.toDate()));
    final tasks = tProv?.tasks ?? const [];
    final show = events.take(3).toList();

    int _completedCountForEvent(dynamic ev) {
      final dueOnOrBefore = ev.eventDate!.toDate();
      final related = tasks.where((t) =>
          (t.initiative?.id != null && ev.initiative?.id == t.initiative?.id) &&
          (t.dueDate != null && !t.dueDate!.toDate().isAfter(dueOnOrBefore))
      );
      int done = 0;
      for (final t in related) {
        final s = t.status.toLowerCase(); // removed unnecessary cast
        if (s == 'done' || s == 'completed' || s == 'closed') done += 1;
      }
      return done;
    }

    int _totalCountForEvent(dynamic ev) {
      final dueOnOrBefore = ev.eventDate!.toDate();
      return tasks.where((t) =>
          (t.initiative?.id != null && ev.initiative?.id == t.initiative?.id) &&
          (t.dueDate != null && !t.dueDate!.toDate().isAfter(dueOnOrBefore))
      ).length;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if ((eProv?.isBusy ?? false) && (eProv?.events.isEmpty ?? true))
              const LinearProgressIndicator(minHeight: 2)
            else if (show.isEmpty)
              const Text('No upcoming events', style: TextStyle(color: Colors.black54))
            else
              ...show.map((e) {
                final total = _totalCountForEvent(e);
                final done = _completedCountForEvent(e);
                final pct = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                          const SizedBox(width: 12),
                          Text(_formatDate(e.eventDate!.toDate()), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.black12, color: MiskTheme.miskGold),
                      ),
                      const SizedBox(height: 4),
                      Text('Preparation: $done of $total tasks completed', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _recentActivitiesSection(BuildContext context) {
    final eProv = context.watch<EventAnnouncementProvider?>();
    final events = eProv?.events ?? const [];

    // Build unified list: recent donations (loaded) + recent events/announcements (from provider)
    final List<_Activity> items = [];

    for (final d in _recentDonations) {
      final ts = (d.receivedAt ?? d.createdAt)?.toDate();
      if (ts == null) continue;
      items.add(_Activity(
        when: ts,
        title: d.donorName.isNotEmpty ? d.donorName : 'Donation', // donorName is non-nullable
        subtitle: '${d.method} • ${_formatCurrency(d.amount)}',
        icon: Icons.payments,
        color: MiskTheme.miskGold,
      ));
    }

    for (final e in events) {
      DateTime? ts;
      String subtitle = 'Announcement';
      if (e.type == 'event') {
        ts = e.eventDate?.toDate();
        subtitle = 'Event on ${ts != null ? _formatDate(ts) : 'TBA'}';
      } else {
        ts = e.createdAt?.toDate() ?? e.updatedAt?.toDate();
        subtitle = 'Announcement';
      }
      ts ??= DateTime.now();
      items.add(_Activity(
        when: ts,
        title: e.title,
        subtitle: subtitle,
        icon: e.type == 'event' ? Icons.event : Icons.campaign,
        color: Colors.blueGrey,
      ));
    }

    items.sort((a, b) => b.when.compareTo(a.when));
    final top = items.take(6).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activities', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                if (_recentBusy) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            if (top.isEmpty)
              const Text('No recent activity', style: TextStyle(color: Colors.black54))
            else
              ...top.map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: a.color.withValues(alpha: 0.1), shape: BoxShape.circle), // replace withOpacity
                          child: Icon(a.icon, size: 16, color: a.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(a.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatDate(a.when), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _Activity {
  final DateTime when;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Activity({required this.when, required this.title, required this.subtitle, required this.icon, required this.color});
}
