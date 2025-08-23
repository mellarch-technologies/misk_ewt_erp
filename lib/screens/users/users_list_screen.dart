import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/security_service.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/state_views.dart';
import '../../widgets/common_card.dart';
import '../../widgets/misk_badge.dart';
import '../../widgets/search_input.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/content_header.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key, this.inShell = false});
  final bool inShell;

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  Widget _buildLoading() {
    // Unified skeleton loader
    return const SkeletonList();
  }

  Future<void> _deleteUser(UserModel user) async {
    // Require re-authentication before deleting a user
    final ok = await const SecurityService().ensureReauthenticated(
      context,
      reason: 'Please confirm your identity to delete user "${user.name}".',
    );
    if (!ok) {
      if (mounted) SnackbarHelper.showInfo(context, 'Action cancelled');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<UserProvider>().removeUser(user.uid);
        if (mounted) {
          SnackbarHelper.showSuccess(context, '${user.name} deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Error deleting user: $e');
        }
      }
    }
  }

  Color _colorFromString(String s) {
    final hash = s.codeUnits.fold<int>(0, (p, c) => p + c);
    const colors = [
      Colors.teal,
      Colors.indigo,
      Colors.deepPurple,
      Colors.brown,
      Colors.blueGrey,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
      Colors.deepOrange,
    ];
    return colors[hash % colors.length];
  }

  MiskBadgeType _statusType(String? status) {
    final v = (status ?? '').toLowerCase();
    if (v.contains('active')) return MiskBadgeType.success;
    if (v.contains('suspend') || v.contains('inactive')) return MiskBadgeType.warning;
    if (v.contains('blocked')) return MiskBadgeType.danger;
    return MiskBadgeType.neutral;
  }

  Widget _buildUserCard(UserModel user) {
    final avatarColor = _colorFromString(user.name);
    final joined = user.createdAt != null ? 'Joined: ${user.createdAt!.toLocal().toString().split(' ').first}' : null;
    final status = user.status;
    final designation = (user.designation != null && user.designation!.isNotEmpty) ? user.designation : null;

    final String? photoUrl = (user.photo != null && user.photo!.startsWith('http')) ? user.photo : null;

    return CommonCard(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/users/form', arguments: user),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: avatarColor,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: MiskTheme.spacingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          switch (val) {
                            case 'edit':
                              Navigator.pushNamed(context, '/users/form', arguments: user);
                              break;
                            case 'delete':
                              _deleteUser(user);
                              break;
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                          PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: MiskTheme.spacingXSmall),
                  Text(user.email, style: TextStyle(color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: MiskTheme.spacingSmall),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (designation != null)
                        MiskBadge(label: designation, type: MiskBadgeType.info, icon: Icons.badge_outlined),
                      if (status != null && status.isNotEmpty)
                        MiskBadge(label: status, type: _statusType(status), icon: Icons.verified_user_outlined),
                      if (joined != null)
                        MiskBadge(label: joined, type: MiskBadgeType.neutral, icon: Icons.calendar_today_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    return RefreshIndicator(
      onRefresh: () => context.read<UserProvider>().fetchUsers(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingSmall),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: MiskTheme.spacingSmall),
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.inShell ? null : AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/users/form'),
          ),
        ],
      ),
      body: Column(
        children: [
          const ContentHeader(title: 'Users'),
          Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: FilterBar(
              children: [
                Expanded(
                  child: SearchInput(
                    controller: _searchController,
                    hintText: 'Search users...',
                    onChanged: (value) => context.read<UserProvider>().setFilter(value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, provider, child) {
                if (provider.hasError) {
                  return ErrorState(
                    title: 'Failed to load users',
                    details: provider.errorMessage,
                    onRetry: () => provider.fetchUsers(),
                  );
                }

                if (provider.isBusy) {
                  return _buildLoading();
                }

                final users = provider.users;
                if (users.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: 'No users found',
                    message: 'Try adjusting filters or add a new user.',
                    action: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/users/form'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add User'),
                    ),
                  );
                }

                return _buildUserList(users);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/users/form'),
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
        backgroundColor: MiskTheme.miskGold,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
