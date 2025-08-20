// lib/screens/settings/global_settings_screen.dart
import 'package:flutter/material.dart';
import '../roles/roles_list_screen.dart';
import '../../theme/app_theme.dart';

class GlobalSettingsScreen extends StatelessWidget {
  const GlobalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Settings'),
        backgroundColor: MiskTheme.miskDarkGreen,
        foregroundColor: MiskTheme.miskWhite,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: MiskTheme.miskGold),
            title: const Text('Roles & Permissions'),
            subtitle: const Text('Manage roles and permissions for all users'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RolesListScreen()),
            ),
          ),
          // Add more global settings here as needed
        ],
      ),
    );
  }
}

