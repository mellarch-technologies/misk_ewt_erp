import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricsRow extends StatelessWidget {
  final String label;
  final double percent;
  final String valueText;
  final Color colorToken;
  final IconData? icon;
  final bool showPercentage;

  const MetricsRow({
    super.key,
    required this.label,
    required this.percent,
    required this.valueText,
    required this.colorToken,
    this.icon,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and percentage row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: colorToken,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.weightMedium,
                  ),
                ),
              ],
            ),
            if (showPercentage)
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.weightBold,
                  color: colorToken,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress bar
        Container(
          height: DesignTokens.progressBarHeight,
          decoration: BoxDecoration(
            color: SemanticColors.neutralGray,
            borderRadius: BorderRadius.circular(DesignTokens.progressBarRadius),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percent / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: colorToken,
                borderRadius: BorderRadius.circular(DesignTokens.progressBarRadius),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Value text caption
        Text(
          valueText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class MilestoneItem extends StatelessWidget {
  final String title;
  final MilestoneStatus status;
  final double? percent;
  final VoidCallback? onStatusToggle;

  const MilestoneItem({
    super.key,
    required this.title,
    required this.status,
    this.percent,
    this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case MilestoneStatus.done:
        statusIcon = Icons.check_circle;
        statusColor = SemanticColors.successGreen;
        break;
      case MilestoneStatus.inProgress:
        statusIcon = Icons.schedule;
        statusColor = SemanticColors.warningGold;
        break;
      case MilestoneStatus.blocked:
        statusIcon = Icons.block;
        statusColor = SemanticColors.dangerRed;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(MiskTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onStatusToggle,
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: MiskTheme.spacingSmall),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.weightMedium,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: DesignTokens.weightMedium,
                  ),
                ),
              ),
            ],
          ),
          if (percent != null) ...[
            const SizedBox(height: MiskTheme.spacingSmall),
            MetricsRow(
              label: 'Progress',
              percent: percent!,
              valueText: '${percent!.toStringAsFixed(0)}% complete',
              colorToken: statusColor,
              showPercentage: false,
            ),
          ],
        ],
      ),
    );
  }
}

enum MilestoneStatus {
  done,
  inProgress,
  blocked;

  String get displayName {
    switch (this) {
      case MilestoneStatus.done:
        return 'Done';
      case MilestoneStatus.inProgress:
        return 'In Progress';
      case MilestoneStatus.blocked:
        return 'Blocked';
    }
  }
}

class CollapsibleSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            decoration: BoxDecoration(
              color: MiskTheme.miskLightGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MiskTheme.borderRadiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.weightSemiBold,
                    color: MiskTheme.miskDarkGreen,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: MiskTheme.miskDarkGreen,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: MiskTheme.spacingSmall),
            child: Column(children: widget.children),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
