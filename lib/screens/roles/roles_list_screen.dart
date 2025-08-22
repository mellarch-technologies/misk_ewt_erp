// lib/screens/roles/roles_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/role_provider.dart';
import '../../services/security_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/state_views.dart';
import 'role_form_screen.dart';
import '../../widgets/back_or_home_button.dart';
import '../../widgets/common_card.dart';
import '../../widgets/misk_badge.dart';

class RolesListScreen extends StatelessWidget {
  const RolesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        leading: const BackOrHomeButton(),
      ),
      body: roleProvider.isLoading
          ? const SkeletonList()
          : (roleProvider.error != null
              ? ErrorState(
                  title: 'Failed to load roles',
                  details: roleProvider.error,
                  onRetry: () {
                    roleProvider.fetchRoles();
                  },
                )
              : (roleProvider.roles.isEmpty
                  ? const EmptyState(
                      icon: Icons.security_outlined,
                      title: 'No roles yet',
                      message: 'Use the button below to add your first role.',
                    )
                  : RefreshIndicator(
                      onRefresh: roleProvider.fetchRoles,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingSmall),
                        itemCount: roleProvider.roles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: MiskTheme.spacingSmall),
                        itemBuilder: (context, i) {
                          final role = roleProvider.roles[i];
                          final protectedBadge = role.protected
                              ? const MiskBadge(label: 'Protected', type: MiskBadgeType.warning, icon: Icons.lock)
                              : null;
                          final createdBadge = (role.createdAt != null)
                              ? MiskBadge(label: 'Created: ${role.createdAt}', type: MiskBadgeType.neutral, icon: Icons.schedule)
                              : null;
                          final updatedBadge = (role.updatedAt != null)
                              ? MiskBadge(label: 'Updated: ${role.updatedAt}', type: MiskBadgeType.neutral, icon: Icons.update)
                              : null;

                          final granted = role.permissions.keys
                              .where((k) => role.permissions[k] == true)
                              .toList();

                          return CommonCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        role.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      onPressed: role.protected
                                          ? null
                                          : () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => RoleFormScreen(role: role),
                                                ),
                                              );
                                              await roleProvider.fetchRoles();
                                            },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: role.protected
                                          ? null
                                          : () async {
                                              final ok = await const SecurityService().ensureReauthenticated(
                                                context,
                                                reason: 'Please confirm your identity to delete the role "${role.name}".',
                                              );
                                              if (!ok) {
                                                if (context.mounted) {
                                                  SnackbarHelper.showInfo(context, 'Action cancelled');
                                                }
                                                return;
                                              }
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Delete Role'),
                                                  content: Text('Are you sure you want to delete the role "${role.name}"?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                      child: const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                try {
                                                  await roleProvider.deleteRole(role.id);
                                                  if (context.mounted) {
                                                    SnackbarHelper.showSuccess(context, 'Role deleted');
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    SnackbarHelper.showError(context, 'Error deleting role: $e');
                                                  }
                                                }
                                              }
                                            },
                                    ),
                                  ],
                                ),
                                if (role.description != null && role.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(role.description!, style: const TextStyle(fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (protectedBadge != null) protectedBadge,
                                    if (createdBadge != null) createdBadge,
                                    if (updatedBadge != null) updatedBadge,
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (granted.isNotEmpty)
                                  Text(
                                    'Permissions: ${granted.join(', ')}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ))) ,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoleFormScreen()),
          );
          await roleProvider.fetchRoles();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Role'),
        backgroundColor: MiskTheme.miskGold,
        foregroundColor: Colors.white,
      ),
    );
  }
}
