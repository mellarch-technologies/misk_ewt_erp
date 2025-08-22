// lib/widgets/misk_badge.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum MiskBadgeType { neutral, info, success, warning, danger }

class MiskBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final MiskBadgeType type;
  final EdgeInsets padding;

  const MiskBadge({super.key, required this.label, this.icon, this.type = MiskBadgeType.neutral, this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4)});

  Color _bg(BuildContext c) {
    switch (type) {
      case MiskBadgeType.info:
        return Theme.of(c).colorScheme.primary.withValues(alpha: 0.12);
      case MiskBadgeType.success:
        return MiskTheme.miskLightGreen.withValues(alpha: 0.15);
      case MiskBadgeType.warning:
        return Colors.amber.withValues(alpha: 0.18);
      case MiskBadgeType.danger:
        return MiskTheme.miskErrorRed.withValues(alpha: 0.15);
      case MiskBadgeType.neutral:
        return Colors.blueGrey.withValues(alpha: 0.12);
    }
  }

  Color _fg(BuildContext c) {
    switch (type) {
      case MiskBadgeType.info:
        return Theme.of(c).colorScheme.primary;
      case MiskBadgeType.success:
        return MiskTheme.miskLightGreen;
      case MiskBadgeType.warning:
        return Colors.amber.shade800;
      case MiskBadgeType.danger:
        return MiskTheme.miskErrorRed;
      case MiskBadgeType.neutral:
        return Colors.blueGrey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fg(context);
    final border = BorderSide(color: fg.withValues(alpha: 0.4));
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: padding,
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.fromBorderSide(border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
