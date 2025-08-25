// lib/widgets/kpi_card.dart
import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<int> Function() loadCount;
  final double? trendPct;

  const KpiCard({
    super.key,
    required this.title,
    required this.icon,
    required this.loadCount,
    this.trendPct,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: loadCount(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (snapshot.hasError) {
                      return Text('-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color));
                    }
                    final count = snapshot.data ?? 0;
                    return Row(
                      children: [
                        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
                        if (trendPct != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _buildTrendBadge(trendPct!),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge(double pct) {
    final isUp = pct >= 0;
    final badgeColor = isUp ? Colors.green : Colors.red;
    final arrow = isUp ? Icons.arrow_upward : Icons.arrow_downward;
    final pctStr = pct.abs().toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(arrow, size: 14, color: badgeColor),
          const SizedBox(width: 2),
          Text('$pctStr%', style: TextStyle(fontSize: 12, color: badgeColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
