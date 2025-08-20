// lib/screens/roles/roles_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/role_provider.dart';
import '../../services/security_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/state_views.dart';
import 'role_form_screen.dart';

class RolesListScreen extends StatelessWidget {
  const RolesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        // rely on theme AppBar colors for consistency
      ),
      body: roleProvider.isLoading
          ? const SkeletonList()
          : (roleProvider.roles.isEmpty
              ? const EmptyState(
                  icon: Icons.security_outlined,
                  title: 'No roles yet',
                  message: 'Use the button below to add your first role.',
                )
              : RefreshIndicator(
                  onRefresh: roleProvider.fetchRoles,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: roleProvider.roles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final role = roleProvider.roles[i];
                      return Card(
                        child: ListTile(
                          title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (role.description != null && role.description!.isNotEmpty)
                                Text(role.description!, style: const TextStyle(fontStyle: FontStyle.italic)),
                              Text('Permissions: ${role.permissions.keys.where((k) => role.permissions[k] == true).join(", ")}'),
                              if (role.createdBy != null)
                                Text('Created by: ${role.createdBy}')
                              else
                                const SizedBox.shrink(),
                              if (role.createdAt != null)
                                Text('Created at: ${role.createdAt}')
                              else
                                const SizedBox.shrink(),
                              if (role.updatedBy != null)
                                Text('Updated by: ${role.updatedBy}')
                              else
                                const SizedBox.shrink(),
                              if (role.updatedAt != null)
                                Text('Updated at: ${role.updatedAt}')
                              else
                                const SizedBox.shrink(),
                              if (role.protected)
                                const Text('System Role (protected)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                        // Re-authenticate before sensitive action
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
                        ), // end ListTile
                      ); // end Card
                    }, // end itemBuilder
                  ), // end ListView.separated
                )), // end RefreshIndicator and ternary branch
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
