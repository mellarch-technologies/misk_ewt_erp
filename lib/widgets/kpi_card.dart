// lib/widgets/kpi_card.dart
import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<int> Function() loadCount;

  const KpiCard({super.key, required this.title, required this.icon, required this.loadCount});

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
                    return Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
