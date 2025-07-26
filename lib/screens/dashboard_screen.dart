// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>().users.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(MiskTheme.spacingLarge),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: MiskTheme.spacingMedium,
          mainAxisSpacing: MiskTheme.spacingMedium,
          children: [
            _StatCard('Total Users', users.toString(), () =>
                Navigator.pushNamed(context, '/users')),
            _StatCard('Members', '—', () {}),
            _StatCard('Staff', '—', () {}),
            _StatCard('Admins', '—', () {}),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final VoidCallback onTap;
  const _StatCard(this.title, this.value, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MiskTheme.miskCream,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}