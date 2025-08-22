// lib/widgets/welcome_banner.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomeBanner extends StatelessWidget {
  final String userName;
  final String? roleName;
  final String? designation;

  const WelcomeBanner({super.key, required this.userName, this.roleName, this.designation});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
    }

  @override
  Widget build(BuildContext context) {
    final greet = _greeting();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MiskTheme.miskDarkGreen, MiskTheme.miskLightGreen],
        ),
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
      ),
      padding: const EdgeInsets.all(MiskTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greet,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: MiskTheme.miskGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Welcome back, $userName',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ((roleName ?? '').isNotEmpty)
                _InfoPill(label: roleName!, icon: Icons.verified_user_outlined),
              if ((designation ?? '').isNotEmpty)
                _InfoPill(label: designation!, icon: Icons.work_outline),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

