// lib/widgets/dashboard_charts.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FinancialDonut extends StatelessWidget {
  final double goal;
  final double confirmed;
  final double reconciled;
  final List<Color>? colors; // [reconciled, confirmedOnly, remaining]
  const FinancialDonut({super.key, required this.goal, required this.confirmed, required this.reconciled, this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cReconciled = (colors != null && colors!.isNotEmpty) ? colors![0] : Colors.green;
    final cConfirmedOnly = (colors != null && colors!.length > 1) ? colors![1] : Colors.orange;
    final cRemaining = (colors != null && colors!.length > 2) ? colors![2] : Colors.grey.shade300;

    final conf = confirmed.clamp(0, goal);
    final rec = reconciled.clamp(0, conf);
    final confOnly = (conf - rec).clamp(0, goal);
    final remaining = (goal - conf).clamp(0, goal);

    final sections = <PieChartSectionData>[
      PieChartSectionData(value: (rec <= 0 ? 0.0001 : rec).toDouble(), color: cReconciled, radius: 34, title: ''),
      PieChartSectionData(value: (confOnly <= 0 ? 0.0001 : confOnly).toDouble(), color: cConfirmedOnly, radius: 34, title: ''),
      PieChartSectionData(value: (remaining <= 0 ? 0.0001 : remaining).toDouble(), color: cRemaining, radius: 34, title: ''),
    ];

    final percent = goal > 0 ? (confirmed / goal * 100).clamp(0, 100) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  startDegreeOffset: -90,
                  sections: sections,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${percent.toStringAsFixed(0)}%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Text('of goal'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            runSpacing: 6,
            children: [
              _legend(cReconciled, 'Reconciled'),
              _legend(cConfirmedOnly, 'Confirmed'),
              _legend(cRemaining, 'Remaining'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label),
        const SizedBox(width: 12),
      ],
    );
  }
}

class MiniTrendChart extends StatelessWidget {
  final List<DateTime> x;
  final List<double> y;
  final Color color;
  const MiniTrendChart({super.key, required this.x, required this.y, required this.color});

  @override
  Widget build(BuildContext context) {
    if (x.isEmpty || y.isEmpty || x.length != y.length) {
      return const SizedBox(height: 120, child: Center(child: Text('No data')));
    }
    // Map to normalized x indexes (0..n-1)
    final spots = <FlSpot>[];
    for (int i = 0; i < x.length; i++) {
      spots.add(FlSpot(i.toDouble(), y[i]));
    }

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
              dotData: const FlDotData(show: false),
            )
          ],
        ),
      ),
    );
  }
}

class TaskStatusBars extends StatelessWidget {
  final Map<String, int> counts;
  const TaskStatusBars({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('No tasks')));
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final theme = Theme.of(context);

    Color colorFor(String k) {
      final s = k.toLowerCase();
      if (s == 'done' || s == 'completed') return Colors.green;
      if (s.contains('progress') || s == 'ongoing') return Colors.blue;
      if (s == 'blocked') return Colors.redAccent;
      return Colors.orange;
    }

    final items = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(e.key, style: theme.textTheme.bodySmall)),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: 10, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6))),
                      FractionallySizedBox(
                        widthFactor: total == 0 ? 0 : (e.value / total).clamp(0, 1),
                        child: Container(height: 10, decoration: BoxDecoration(color: colorFor(e.key), borderRadius: BorderRadius.circular(6))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 28, child: Text('${e.value}', textAlign: TextAlign.right, style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
      ],
    );
  }
}
