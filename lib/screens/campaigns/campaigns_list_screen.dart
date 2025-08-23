import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/state_views.dart';
import 'campaign_form_screen.dart';
import '../donations/donations_list_screen.dart';
import '../../widgets/back_or_home_button.dart';
import '../../theme/app_theme.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/common_card.dart';
import '../../widgets/misk_badge.dart';
import '../../widgets/search_input.dart';
import '../../widgets/content_header.dart';

class CampaignsListScreen extends StatefulWidget {
  const CampaignsListScreen({super.key, this.inShell = false});
  final bool inShell;

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

  Widget _buildFilterBar(CampaignProvider provider) {
    final cats = <String>{}
      ..addAll(provider.campaigns.map((e) => e.category).whereType<String>().where((c) => c.isNotEmpty));
    if (cats.isEmpty) cats.addAll(['online', 'offline']);

    return FilterBar(
      children: [
        SizedBox(
          width: 320,
          child: SearchInput(
            controller: _searchController,
            hintText: 'Search campaigns...',
            onChanged: (v) => provider.setFilter(v),
          ),
        ),
        const SizedBox(width: MiskTheme.spacingSmall),
        ...cats.map((c) {
          final selected = provider.categoryFilters.contains(c);
          return FilterChip(
            label: Text(c),
            selected: selected,
            onSelected: (_) => provider.toggleCategory(c),
          );
        }),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: provider.publicOnly, onChanged: provider.setPublicOnly),
            const Text('Public only'),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            _searchController.clear();
            provider.setFilter('');
            for (final c in List<String>.from(provider.categoryFilters)) {
              provider.toggleCategory(c);
            }
            if (provider.publicOnly) provider.setPublicOnly(false);
          },
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.inShell ? null : AppBar(
        title: const Text('Campaigns'),
        leading: const BackOrHomeButton(),
      ),
      body: Column(
        children: [
          const ContentHeader(title: 'Campaigns'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MiskTheme.spacingMedium,
              MiskTheme.spacingMedium,
              MiskTheme.spacingMedium,
              MiskTheme.spacingSmall,
            ),
            child: Consumer<CampaignProvider>(builder: (_, p, __) => _buildFilterBar(p)),
          ),
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
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MiskTheme.spacingMedium,
                      vertical: MiskTheme.spacingSmall,
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: MiskTheme.spacingSmall),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final c = items[i];
                      final initName = provider.initiativeNameFor(c.initiative);
                      return CommonCard(
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CampaignFormScreen(campaign: c)),
                          );
                          if (changed == true) await provider.fetchCampaigns();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
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
                              ],
                            ),
                            if ((c.description ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(c.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if ((c.category ?? '').isNotEmpty)
                                  MiskBadge(label: c.category!),
                                if (c.publicVisible)
                                  const MiskBadge(label: 'Public', type: MiskBadgeType.info, icon: Icons.public),
                                if (c.featured)
                                  const MiskBadge(label: 'Featured', type: MiskBadgeType.warning, icon: Icons.star),
                                if (c.initiative != null)
                                  MiskBadge(
                                    label: (initName == null || initName.isEmpty) ? 'Initiative' : initName,
                                    icon: Icons.rocket_launch,
                                    type: MiskBadgeType.neutral,
                                  ),
                              ],
                            ),
                          ],
                        ),
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
