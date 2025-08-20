import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/initiative_service.dart';
import '../../services/campaign_service.dart';
import '../../models/initiative_model.dart';
import '../../models/campaign_model.dart';
import 'donations_list_screen.dart';
import '../../widgets/back_or_home_button.dart';
import '../../theme/app_theme.dart';

class DonationsEntryScreen extends StatefulWidget {
  const DonationsEntryScreen({super.key});

  @override
  State<DonationsEntryScreen> createState() => _DonationsEntryScreenState();
}

class _DonationsEntryScreenState extends State<DonationsEntryScreen> {
  late Future<List<Initiative>> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = InitiativeService().getInitiativesOnce();
  }

  Future<void> _openCampaignPicker(BuildContext context, Initiative init) async {
    final all = await CampaignService().getCampaignsOnce();
    final matching = all.where((c) => c.initiative?.id == init.id).toList();
    if (!mounted) return;
    if (matching.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No campaigns linked to this initiative.')));
      return;
    }
    final selected = await showModalBottomSheet<Campaign>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: matching.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final c = matching[i];
            return ListTile(
              leading: const Icon(Icons.campaign),
              title: Text(c.name),
              subtitle: (c.description ?? '').isNotEmpty ? Text(c.description!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
              onTap: () => Navigator.pop(ctx, c),
            );
          },
        ),
      ),
    );
    if (selected != null && mounted) {
      final initRef = FirebaseFirestore.instance.collection('initiatives').doc(init.id);
      final campRef = FirebaseFirestore.instance.collection('campaigns').doc(selected.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DonationsListScreen(initiativeRef: initRef, campaignRef: campRef),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donations'), leading: const BackOrHomeButton()),
      body: FutureBuilder<List<Initiative>>(
        future: _initFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const <Initiative>[];
          if (items.isEmpty) {
            return const Center(child: Text('No initiatives found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingSmall),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final init = items[i];
              return ListTile(
                leading: const Icon(Icons.flag),
                title: Text(init.title),
                subtitle: (init.description ?? '').isNotEmpty ? Text(init.description!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                onTap: () {
                  final ref = FirebaseFirestore.instance.collection('initiatives').doc(init.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonationsListScreen(initiativeRef: ref),
                    ),
                  );
                },
                trailing: IconButton(
                  tooltip: 'View by Campaign',
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _openCampaignPicker(context, init),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
