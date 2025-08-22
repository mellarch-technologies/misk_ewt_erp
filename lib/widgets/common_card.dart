// lib/widgets/common_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CommonCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const CommonCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(MiskTheme.spacingMedium)});

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge), child: card);
  }
}

