import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/permission_provider.dart';
import '../../widgets/user_card.dart';
import '../../theme/app_theme.dart';
import 'user_form_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});
  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // -- CORRECT PROVIDER USAGE here:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
    // Listen to search changes...
    _searchController.addListener(() {
      Provider.of<UserProvider>(context, listen: false).setFilter(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final permissionProvider = context.watch<PermissionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: MiskTheme.miskDarkGreen,
        foregroundColor: MiskTheme.miskWhite,
        elevation: 1,
        actions: [
          if(permissionProvider.can('can_manage_users'))
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Import Users',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import feature coming soon!')),
                );
              },
            ),
        ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name, email, role, etc.',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: userProvider.isBusy
          ? const Center(child: CircularProgressIndicator(color: MiskTheme.miskGold))
          : userProvider.users.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No users found.' : 'No matching users.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (permissionProvider.can('can_manage_users'))
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserFormScreen()),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text('Add New User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MiskTheme.miskGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: userProvider.users.length,
        itemBuilder: (context, index) {
          final user = userProvider.users[index];
          return UserCard(
            user: user,
            onEdit: permissionProvider.can('can_manage_users') ? () =>() async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => UserFormScreen(user: user)));
              await Provider.of<UserProvider>(context, listen: false).fetchUsers();
            } : null,
            onDelete: permissionProvider.can('can_manage_users') && !user.isSuperAdmin
                ? () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete User'),
                  content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ) ?? false;
              if (confirmed) {
                await userProvider.removeUser(user.uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} deleted.')),
                );
              }
            }
                : null,
          );
        },
      ),
      floatingActionButton: permissionProvider.can('can_manage_users')
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const UserFormScreen()));
          await Provider.of<UserProvider>(context, listen: false).fetchUsers();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add New User'),
        backgroundColor: MiskTheme.miskGold,
        foregroundColor: Colors.white,
      )
          : null,
    );
  }
}
