import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/state_views.dart';
import 'campaign_form_screen.dart';
import '../donations/donations_list_screen.dart';
import '../../widgets/back_or_home_button.dart';
import '../../theme/app_theme.dart';

class CampaignsListScreen extends StatefulWidget {
  const CampaignsListScreen({super.key});

  @override
  State<CampaignsListScreen> createState() => _CampaignsListScreenState();
}

class _CampaignsListScreenState extends State<CampaignsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().fetchCampaigns();
    });
  }

  Widget _buildLoading() => const SkeletonList();

  Widget _buildFilters(CampaignProvider provider) {
    final cats = <String>{}
      ..addAll(provider.campaigns.map((e) => e.category).whereType<String>().where((c) => c.isNotEmpty));
    if (cats.isEmpty) cats.addAll(['online', 'offline']);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: cats.map((c) {
              final selected = provider.categoryFilters.contains(c);
              return FilterChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) => provider.toggleCategory(c),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Switch(
              value: provider.publicOnly,
              onChanged: provider.setPublicOnly,
            ),
            const SizedBox(width: 8),
            const Text('Public only'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        leading: const BackOrHomeButton(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MiskTheme.spacingMedium,
              MiskTheme.spacingMedium,
              MiskTheme.spacingMedium,
              MiskTheme.spacingSmall,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search campaigns...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (v) => context.read<CampaignProvider>().setFilter(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
            child: Consumer<CampaignProvider>(
              builder: (_, p, __) => _buildFilters(p),
            ),
          ),
          const SizedBox(height: MiskTheme.spacingSmall),
          Expanded(
            child: Consumer<CampaignProvider>(
              builder: (context, provider, _) {
                if (provider.hasError) {
                  return ErrorState(
                    title: 'Failed to load campaigns',
                    details: provider.errorMessage,
                    onRetry: () => provider.fetchCampaigns(),
                  );
                }
                if (provider.isBusy) return _buildLoading();

                final items = provider.campaigns;
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No campaigns found',
                    message: 'Try adding a campaign or adjusting filters.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.fetchCampaigns,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingSmall),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final c = items[i];
                      final initName = provider.initiativeNameFor(c.initiative);
                      return ListTile(
                        title: Text(c.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((c.description ?? '').isNotEmpty)
                              Text(c.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if ((c.category ?? '').isNotEmpty)
                                  Chip(label: Text(c.category!), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                if (c.publicVisible)
                                  const Chip(label: Text('Public'), visualDensity: VisualDensity.compact),
                                if (c.featured)
                                  Chip(label: const Text('Featured'), visualDensity: VisualDensity.compact, side: BorderSide(color: Colors.amber.shade300)),
                                if (c.initiative != null)
                                  Chip(
                                    label: Text(initName == null || initName.isEmpty ? 'Initiative' : initName),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: 'View Donations',
                          icon: const Icon(Icons.receipt_long),
                          onPressed: () {
                            final initRef = c.initiative;
                            if (initRef == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link this campaign to an initiative to view donations.')),
                              );
                              return;
                            }
                            final campRef = FirebaseFirestore.instance.collection('campaigns').doc(c.id);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DonationsListScreen(initiativeRef: initRef, campaignRef: campRef),
                              ),
                            );
                          },
                        ),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CampaignFormScreen(campaign: c)),
                          );
                          if (changed == true) await provider.fetchCampaigns();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CampaignFormScreen()),
          );
          if (changed == true && mounted) {
            await context.read<CampaignProvider>().fetchCampaigns();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
