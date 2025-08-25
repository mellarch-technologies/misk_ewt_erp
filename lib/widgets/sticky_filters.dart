import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StickyFilters extends StatelessWidget {
  final List<Widget> children;
  final bool isSticky;
  final VoidCallback? onClearAll;
  final int resultCount;
  final List<Widget> activeFilters;

  const StickyFilters({
    super.key,
    required this.children,
    this.isSticky = false,
    this.onClearAll,
    this.resultCount = 0,
    this.activeFilters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSticky ? Theme.of(context).scaffoldBackgroundColor : null,
        boxShadow: isSticky
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: MiskTheme.spacingSmall,
                    runSpacing: MiskTheme.spacingSmall,
                    children: children,
                  ),
                ),
                if (resultCount > 0) ...[
                  const SizedBox(width: MiskTheme.spacingMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: MiskTheme.miskGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$resultCount results',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MiskTheme.miskDarkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (activeFilters.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: MiskTheme.spacingMedium,
                vertical: MiskTheme.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: MiskTheme.miskGold.withValues(alpha: 0.05),
                border: Border(
                  top: BorderSide(
                    color: MiskTheme.miskGold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Wrap(
                spacing: MiskTheme.spacingSmall,
                runSpacing: MiskTheme.spacingSmall,
                children: [
                  ...activeFilters,
                  if (onClearAll != null)
                    ActionChip(
                      label: const Text('Clear all'),
                      onPressed: onClearAll,
                      backgroundColor: MiskTheme.miskErrorRed.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: MiskTheme.miskErrorRed.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  final IconData? icon;

  const ActiveFilterChip({
    super.key,
    required this.label,
    required this.onDeleted,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 18) : null,
      onDeleted: onDeleted,
      backgroundColor: MiskTheme.miskLightGreen.withValues(alpha: 0.1),
      deleteIconColor: MiskTheme.miskDarkGreen,
      side: BorderSide(
        color: MiskTheme.miskLightGreen.withValues(alpha: 0.3),
      ),
    );
  }
}
