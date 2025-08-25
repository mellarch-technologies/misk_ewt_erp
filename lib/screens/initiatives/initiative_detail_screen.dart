import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/initiative_model.dart';
import '../../services/currency_helper.dart';
import '../donations/donations_list_screen.dart';
import '../../services/rollup_service.dart' as roll;
import '../../theme/app_theme.dart';
import '../../widgets/metrics_components.dart';

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

  Widget _buildCompactMetricsSection(BuildContext context) {
    final goal = initiative.goalAmount ?? 0;
    final confirmed = initiative.computedRaisedAmount ?? (initiative.raisedAmount ?? 0);
    final reconciled = initiative.reconciledRaisedAmount ?? 0;
    final execProgress = _execProgress();

    return Container(
      margin: const EdgeInsets.all(MiskTheme.spacingMedium),
      padding: const EdgeInsets.all(MiskTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13), // 0.05 * 255 ≈ 13
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Metrics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.weightSemiBold,
              color: MiskTheme.miskDarkGreen,
            ),
          ),
          const SizedBox(height: MiskTheme.spacingMedium),

          // Financial Confirmed
          if (goal > 0) ...[
            MetricsRow(
              label: 'Financial Confirmed',
              percent: (confirmed / goal * 100).clamp(0, 100),
              valueText: '${CurrencyHelper.formatInr(confirmed)} / ${CurrencyHelper.formatInr(goal)} - Confirmed',
              colorToken: SemanticColors.accentGold,
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: MiskTheme.spacingMedium),

            // Reconciled in Bank
            MetricsRow(
              label: 'Reconciled in Bank',
              percent: (reconciled / goal * 100).clamp(0, 100),
              valueText: '${CurrencyHelper.formatInr(reconciled)} / ${CurrencyHelper.formatInr(goal)} - Reconciled',
              colorToken: SemanticColors.successGreen,
              icon: Icons.verified_user,
            ),
            const SizedBox(height: MiskTheme.spacingMedium),
          ],

          // Execution Progress
          if (execProgress != null)
            MetricsRow(
              label: 'Execution Progress',
              percent: (execProgress * 100).clamp(0, 100),
              valueText: '${(execProgress * 100).toStringAsFixed(1)}% - Project completion',
              colorToken: SemanticColors.infoBlue,
              icon: Icons.engineering,
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMilestonesSection(BuildContext context) {
    final milestones = initiative.milestones ?? [];
    if (milestones.isEmpty) return const SizedBox.shrink();

    // Group milestones by phase (if phase field exists)
    final Map<String, List<Map<String, dynamic>>> groupedMilestones = {};
    for (final milestone in milestones) {
      final phase = milestone['phase']?.toString() ?? 'General';
      groupedMilestones.putIfAbsent(phase, () => []).add(milestone);
    }

    return Container(
      margin: const EdgeInsets.all(MiskTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: MiskTheme.miskDarkGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Project Milestones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.weightSemiBold,
                  color: MiskTheme.miskDarkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: MiskTheme.spacingMedium),

          ...groupedMilestones.entries.map((entry) {
            final phase = entry.key;
            final phaseMilestones = entry.value;

            return CollapsibleSection(
              title: phase,
              children: phaseMilestones.map((milestone) {
                final title = milestone['title']?.toString() ?? 'Untitled';
                final percent = milestone['percent']?.toDouble();
                final completed = milestone['completed'] == true;
                final blocked = milestone['blocked'] == true;

                MilestoneStatus status;
                if (completed) {
                  status = MilestoneStatus.done;
                } else if (blocked) {
                  status = MilestoneStatus.blocked;
                } else {
                  status = MilestoneStatus.inProgress;
                }

                return MilestoneItem(
                  title: title,
                  status: status,
                  percent: percent,
                  onStatusToggle: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Milestone status toggle coming soon')),
                    );
                  },
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    final gallery = initiative.gallery ?? [];
    if (gallery.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gallery.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                gallery[i],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = _dateRange();
    final execProgress = _execProgress();

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
              final Map<String, dynamic>? data = snap.data();
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
              padding: const EdgeInsets.all(MiskTheme.spacingMedium),
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

                  // Compact Metrics Section
                  _buildCompactMetricsSection(context),

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
                              builder: (_) => DonationsListScreen(
                                initiativeRef: FirebaseFirestore.instance.doc('initiatives/${initiative.id}')
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('View Donations'),
                      ),
                    ],
                  ),

                  // Enhanced Milestones Section
                  _buildEnhancedMilestonesSection(context),

                  // Gallery Section
                  _buildGallerySection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
