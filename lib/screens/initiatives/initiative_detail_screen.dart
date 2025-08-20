import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/initiative_model.dart';
import '../../services/currency_helper.dart';
import '../donations/donations_list_screen.dart';
import '../../services/rollup_service.dart' as roll;

class InitiativeDetailScreen extends StatelessWidget {
  final Initiative initiative;
  const InitiativeDetailScreen({super.key, required this.initiative});

  String _dateRange() {
    final s = initiative.startDate?.toDate();
    final e = initiative.endDate?.toDate();
    if (s == null && e == null) return '';
    final sd = s != null ? s.toLocal().toString().split(' ').first : '';
    final ed = e != null ? e.toLocal().toString().split(' ').first : '';
    return [sd, ed].where((x) => x.isNotEmpty).join(' → ');
  }

  double? _execProgress() {
    // Prefer computedExecutionPercent if present
    final p = initiative.computedExecutionPercent;
    if (p is num) return (p.clamp(0, 100) / 100).toDouble();
    // Fallback: average of milestone percents
    final ms = initiative.milestones ?? [];
    if (ms.isEmpty) return null;
    final vals = ms
        .map((m) => m['percent'])
        .whereType<num>()
        .map((e) => e.toDouble().clamp(0, 100))
        .toList();
    if (vals.isEmpty) return null;
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    return (avg / 100).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = _dateRange();
    final execProgress = _execProgress();

    final goal = initiative.goalAmount ?? 0;
    final confirmed = initiative.computedRaisedAmount ?? (initiative.raisedAmount ?? 0);
    final reconciled = initiative.reconciledRaisedAmount ?? 0;
    final finProgress = goal > 0 ? (confirmed / goal).clamp(0, 1).toDouble() : null;
    final recProgress = goal > 0 ? (reconciled / goal).clamp(0, 1).toDouble() : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(initiative.title),
        actions: [
          if (initiative.publicVisible)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Chip(label: Text('Public'), visualDensity: VisualDensity.compact),
            ),
          if (initiative.featured)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(label: Text('Featured'), visualDensity: VisualDensity.compact),
            ),
          IconButton(
            tooltip: 'Recompute totals',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final ref = FirebaseFirestore.instance.doc('initiatives/${initiative.id}');
              await roll.RollupService().recomputeInitiativeFinancial(ref);
              // Fetch latest snapshot and pop-push to refresh UI
              final snap = await ref.get();
              final data = snap.data() as Map<String, dynamic>?;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recomputed financial totals.')),
                );
                if (data != null) {
                  final updated = Initiative.fromFirestore(data, initiative.id);
                  // Replace route with updated instance
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => InitiativeDetailScreen(initiative: updated),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or placeholder
            SizedBox(
              height: 180,
              width: double.infinity,
              child: (initiative.coverImageUrl != null && initiative.coverImageUrl!.isNotEmpty)
                  ? Image.network(initiative.coverImageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      alignment: Alignment.center,
                      child: Icon(Icons.flag, size: 48, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(initiative.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((initiative.category ?? '').isNotEmpty)
                        Chip(label: Text(initiative.category!)),
                      if ((initiative.status).isNotEmpty)
                        Chip(
                          label: Text(initiative.status),
                          side: BorderSide(color: Colors.blueGrey.shade200),
                        ),
                      if (dateRange.isNotEmpty)
                        Chip(label: Text(dateRange), backgroundColor: Colors.blue.shade50),
                      if ((initiative.location ?? '').isNotEmpty)
                        Chip(label: Text(initiative.location!)),
                    ],
                  ),
                  if ((initiative.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(initiative.description!),
                  ],

                  // Financial Progress (Confirmed & Reconciled)
                  if (finProgress != null) ...[
                    const SizedBox(height: 20),
                    const Text('Financial Progress (Confirmed)'),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: finProgress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${(finProgress * 100).toStringAsFixed(0)}%  ('
                        '${CurrencyHelper.formatInr(confirmed)} / ${CurrencyHelper.formatInr(goal)})'),
                  ],
                  if (recProgress != null) ...[
                    const SizedBox(height: 12),
                    const Text('Reconciled in Bank'),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: recProgress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${(recProgress * 100).toStringAsFixed(0)}%  ('
                        '${CurrencyHelper.formatInr(reconciled)} / ${CurrencyHelper.formatInr(goal)})'),
                    const SizedBox(height: 6),
                    Text('Note: Reconciled = bank-reflected donations',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],

                  // Execution Progress
                  if (execProgress != null) ...[
                    const SizedBox(height: 20),
                    const Text('Execution Progress'),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: execProgress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${(execProgress * 100).toStringAsFixed(0)}%'),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DonationsListScreen(initiativeRef: FirebaseFirestore.instance.doc('initiatives/${initiative.id}')),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('View Donations'),
                      ),
                    ],
                  ),

                  if ((initiative.milestones ?? []).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Milestones', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...initiative.milestones!.map((m) {
                      final title = (m['title'] ?? '').toString();
                      final percent = (m['percent'] is num) ? (m['percent'] as num).toDouble() : null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title),
                            if (percent != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: LinearProgressIndicator(
                                  value: (percent / 100).clamp(0, 1),
                                  minHeight: 6,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  if ((initiative.gallery ?? []).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: initiative.gallery!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            initiative.gallery![i],
                            width: 140,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 140,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
