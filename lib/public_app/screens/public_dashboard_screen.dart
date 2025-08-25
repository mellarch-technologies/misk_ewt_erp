// lib/public_app/screens/public_dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'donate_home_screen.dart';

class PublicDashboardScreen extends StatefulWidget {
  const PublicDashboardScreen({super.key});

  @override
  State<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends State<PublicDashboardScreen> {
  late final FirebaseFirestore _db;

  @override
  void initState() {
    super.initState();
    _db = FirebaseFirestore.instance;
  }

  Future<int> _countPublic(
    String collection, {
    List<Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)>? filters,
  }) async {
    Query<Map<String, dynamic>> q = _db.collection(collection);
    q = q.where('publicVisible', isEqualTo: true);
    if (filters != null) {
      for (final f in filters) {
        q = f(q);
      }
    }
    final snap = await q.count().get();
    return snap.count ?? 0;
  }

  Future<_FinanceTotals> _fetchFinanceTotals() async {
    final q = await _db
        .collection('initiatives')
        .where('publicVisible', isEqualTo: true)
        .get();
    num goal = 0;
    num confirmed = 0;
    num reconciled = 0;
    for (final d in q.docs) {
      final data = d.data();
      final g = _toNum(data['goalAmount']) ?? 0;
      final c = _toNum(data['computedRaisedAmount']) ?? 0;
      final r = _toNum(data['reconciledRaisedAmount']) ?? 0;
      goal += g;
      confirmed += c;
      reconciled += r;
    }
    return _FinanceTotals(goal: goal, confirmed: confirmed, reconciled: reconciled);
  }

  Future<List<_EventItem>> _fetchUpcomingEvents() async {
    final now = Timestamp.fromDate(DateTime.now());
    final snap = await _db
        .collection('events_announcements')
        .where('publicVisible', isEqualTo: true)
        .where('type', isEqualTo: 'event')
        .where('eventDate', isGreaterThanOrEqualTo: now)
        .orderBy('eventDate', descending: false)
        .limit(3)
        .get();
    return snap.docs.map((d) {
      final m = d.data();
      return _EventItem(
        title: (m['title'] ?? '').toString(),
        when: (m['eventDate'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  Future<List<_InitiativeCardData>> _fetchFeaturedInitiatives() async {
    final snap = await _db
        .collection('initiatives')
        .where('publicVisible', isEqualTo: true)
        .where('featured', isEqualTo: true)
        .limit(10)
        .get();
    return snap.docs.map((d) {
      final m = d.data();
      final goal = _toNum(m['goalAmount']) ?? 0;
      final confirmed = _toNum(m['computedRaisedAmount']) ?? 0;
      final pct = goal <= 0 ? 0.0 : (confirmed / goal).clamp(0, 1).toDouble();
      return _InitiativeCardData(
        title: (m['title'] ?? '').toString(),
        goal: goal,
        confirmed: confirmed,
        progress: pct,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MiSK EWT')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: MiskTheme.miskGold,
            child: const ListTile(
              title: Text('Welcome', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Transparency • Service • Impact', style: TextStyle(color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<int>>(
            future: Future.wait<int>([
              _countPublic('initiatives'),
              _countPublic('campaigns'),
              _countPublic('events_announcements', filters: [
                (q) => q.where('type', isEqualTo: 'event'),
              ]),
            ]),
            builder: (context, snap) {
              final vals = snap.data ?? const [0, 0, 0];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi('Initiatives', vals[0].toString(), Icons.flag),
                  _kpi('Campaigns', vals[1].toString(), Icons.campaign),
                  _kpi('Upcoming Events', vals[2].toString(), Icons.event),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<_FinanceTotals>(
            future: _fetchFinanceTotals(),
            builder: (context, snap) {
              final t = snap.data ?? const _FinanceTotals(goal: 0, confirmed: 0, reconciled: 0);
              final pct = t.goal <= 0 ? 0.0 : (t.confirmed / t.goal).clamp(0, 1).toDouble();
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Financial Progress (Public)', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _miniStat('Goal', _formatCurrency(t.goal))),
                        const SizedBox(width: 12),
                        Expanded(child: _miniStat('Confirmed', _formatCurrency(t.confirmed))),
                        const SizedBox(width: 12),
                        Expanded(child: _miniStat('Reconciled', _formatCurrency(t.reconciled))),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.black12, color: MiskTheme.miskGold),
                      ),
                      const SizedBox(height: 6),
                      Text('Overall: ${(pct * 100).toStringAsFixed(1)}% of goal', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Featured Initiatives', style: TextStyle(fontWeight: FontWeight.w700)),
              TextButton.icon(
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('Donate Now'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonateHomeScreen())),
              )
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<_InitiativeCardData>>(
            future: _fetchFeaturedInitiatives(),
            builder: (context, snap) {
              final list = snap.data ?? const <_InitiativeCardData>[];
              if (list.isEmpty) {
                return const Text('No featured initiatives yet', style: TextStyle(color: Colors.black54));
              }
              return SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final it = list[i];
                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(value: it.progress, minHeight: 8, backgroundColor: Colors.black12, color: MiskTheme.miskGold),
                          ),
                          const SizedBox(height: 6),
                          Text('${_formatCurrency(it.confirmed)} of ${_formatCurrency(it.goal)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FutureBuilder<List<_EventItem>>(
            future: _fetchUpcomingEvents(),
            builder: (context, snap) {
              final list = snap.data ?? const <_EventItem>[];
              if (list.isEmpty) {
                return const Text('No upcoming events', style: TextStyle(color: Colors.black54));
              }
              return Column(
                children: list.map((e) => Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Colors.black54),
                    title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(e.when != null ? _formatDate(e.when!) : 'Date TBA'),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
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

  String _formatCurrency(num v) => '₹${v.toStringAsFixed(0)}';
  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  num? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v.replaceAll(',', '').trim());
    return null;
  }
}

class _FinanceTotals {
  final num goal;
  final num confirmed;
  final num reconciled;
  const _FinanceTotals({required this.goal, required this.confirmed, required this.reconciled});
}

class _EventItem {
  final String title;
  final DateTime? when;
  _EventItem({required this.title, required this.when});
}

class _InitiativeCardData {
  final String title;
  final num goal;
  final num confirmed;
  final double progress;
  _InitiativeCardData({required this.title, required this.goal, required this.confirmed, required this.progress});
}
