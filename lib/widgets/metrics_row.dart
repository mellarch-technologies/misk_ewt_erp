import 'package:flutter/material.dart';

class MetricsRow extends StatelessWidget {
  final String label;
  final String percentText;
  final String valueText;
  final Color color;
  final double percent; // 0.0 - 1.0

  const MetricsRow({
    super.key,
    required this.label,
    required this.percentText,
    required this.valueText,
    required this.color,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(percentText, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 2),
        Text(valueText, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
