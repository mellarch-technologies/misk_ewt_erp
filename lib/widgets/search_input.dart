// lib/widgets/search_input.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final double borderRadius;
  final bool dense;

  const SearchInput({super.key, required this.controller, required this.hintText, this.onChanged, this.borderRadius = 30, this.dense = true});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius)),
        isDense: dense,
        contentPadding: const EdgeInsets.symmetric(vertical: MiskTheme.spacingSmall, horizontal: MiskTheme.spacingMedium),
      ),
      onChanged: onChanged,
    );
  }
}

