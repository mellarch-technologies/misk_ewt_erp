// lib/screens/users/users_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_card.dart';
import '../../theme/app_theme.dart';
import 'user_form_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});
  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<UserProvider>(context, listen: false).fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: prov.setFilter,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MiskTheme.miskGold,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserFormScreen()),
        ),
        child: const Icon(Icons.person_add),
      ),
      body: prov.isBusy
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: prov.users.length,
        itemBuilder: (_, i) => UserCard(
          user: prov.users[i],
          onEdit: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UserFormScreen(user: prov.users[i]),
            ),
          ),
          onDelete: () => prov.removeUser(prov.users[i].uid),
        ),
      ),
    );
  }
}
