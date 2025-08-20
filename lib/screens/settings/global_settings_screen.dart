// lib/screens/settings/global_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../roles/roles_list_screen.dart';
import '../security/app_lock_settings_screen.dart';
import '../../theme/app_theme.dart';
import 'payment_settings_screen.dart';
import '../../services/rollup_service.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/back_or_home_button.dart';

class GlobalSettingsScreen extends StatelessWidget {
  const GlobalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Settings'),
        leading: const BackOrHomeButton(),
        // rely on theme for colors to keep headers consistent
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
          ListTile(
            leading: const Icon(Icons.security, color: MiskTheme.miskGold),
            title: const Text('Security & App Lock'),
            subtitle: const Text('Enable app lock, set PIN/biometrics, idle timeout'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: MiskTheme.miskGold),
            title: const Text('Payments'),
            subtitle: const Text('Razorpay, UPI and Bank details for Public App'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentSettingsScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync, color: MiskTheme.miskGold),
            title: const Text('Recompute roll-ups (all initiatives)'),
            subtitle: const Text('Refresh financial totals from donations'),
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              try {
                final snap = await FirebaseFirestore.instance.collection('initiatives').get();
                final svc = RollupService();
                for (final doc in snap.docs) {
                  await svc.recomputeInitiativeFinancial(doc.reference);
                }
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                SnackbarHelper.showSuccess(context, 'Recomputed for ${snap.docs.length} initiatives');
              } catch (e) {
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                SnackbarHelper.showError(context, 'Failed: $e');
              }
            },
          ),
          // Add more global settings here as needed
        ],
      ),
    );
  }
}
