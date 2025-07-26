// lib/screens/members/members_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/member_card.dart';
import '../../theme/app_theme.dart' show MiskTheme;
import 'member_form_screen.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<MemberProvider>(context, listen: false).fetchMembers();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MemberProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MiskTheme.miskGold,
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: prov.isBusy
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
          itemCount: prov.members.length,
          itemBuilder: (_, i) => MemberCard(
            member: prov.members[i],
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberFormScreen(member: prov.members[i]),
              ),
            ),
          )),
    );
  }
}
