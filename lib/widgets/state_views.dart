// lib/widgets/state_views.dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'Nothing here yet',
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: TextStyle(color: Colors.grey.shade700)),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ]
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String title;
  final String? details;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.title = 'Something went wrong', this.details, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (details != null) ...[
              const SizedBox(height: 6),
              Text(details!, textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ]
          ],
        ),
      ),
    );
  }
}

