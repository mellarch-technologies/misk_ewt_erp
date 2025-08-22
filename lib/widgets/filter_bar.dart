// lib/widgets/filter_bar.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterBar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const FilterBar({super.key, required this.children, this.padding = const EdgeInsets.all(MiskTheme.spacingSmall)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Wrap(
        spacing: MiskTheme.spacingSmall,
        runSpacing: MiskTheme.spacingSmall,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

