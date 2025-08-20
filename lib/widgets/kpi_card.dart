// lib/widgets/kpi_card.dart
import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<int> Function() loadCount;

  const KpiCard({super.key, required this.title, required this.icon, required this.loadCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: loadCount(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
                    }
                    final count = snapshot.data ?? 0;
                    return Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
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

