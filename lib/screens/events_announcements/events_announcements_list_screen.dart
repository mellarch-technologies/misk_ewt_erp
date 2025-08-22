import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_announcement_provider.dart';
import '../../widgets/state_views.dart';
import '../../services/security_service.dart';
import '../../widgets/snackbar_helper.dart';
import 'event_announcement_form_screen.dart';
import '../../widgets/back_or_home_button.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_card.dart';
import '../../widgets/misk_badge.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/search_input.dart';

class EventsAnnouncementsListScreen extends StatefulWidget {
  const EventsAnnouncementsListScreen({super.key});

  @override
  State<EventsAnnouncementsListScreen> createState() => _EventsAnnouncementsListScreenState();
}

class _EventsAnnouncementsListScreenState extends State<EventsAnnouncementsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventAnnouncementProvider>().fetchEvents();
    });
  }

  Widget _buildLoading() {
    // Unified skeleton loader
    return const SkeletonList();
  }

  Widget _filters(EventAnnouncementProvider p) {
    final types = const ['All', 'event', 'announcement'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingXSmall),
      child: FilterBar(
        children: [
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              key: ValueKey('type_${p.typeFilter}'),
              isExpanded: true,
              initialValue: p.typeFilter,
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => p.setTypeFilter(v ?? 'All'),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ),
          Row(children: [
            Switch(value: p.publicOnly, onChanged: p.setPublicOnly),
            const Text('Public only'),
          ]),
          TextButton.icon(
            onPressed: () {
              p.setTypeFilter('All');
              p.setPublicOnly(false);
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  MiskBadgeType _typeBadgeType(String t) {
    final v = t.toLowerCase();
    if (v == 'event') return MiskBadgeType.info;
    if (v == 'announcement') return MiskBadgeType.neutral;
    return MiskBadgeType.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events & Announcements'), leading: const BackOrHomeButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: SearchInput(
              controller: _searchController,
              hintText: 'Search events & announcements...',
              onChanged: (v) => context.read<EventAnnouncementProvider>().setFilter(v),
            ),
          ),
          Consumer<EventAnnouncementProvider>(builder: (_, p, __) => _filters(p)),
          const SizedBox(height: MiskTheme.spacingXSmall),
          Expanded(
            child: Consumer<EventAnnouncementProvider>(
              builder: (context, provider, _) {
                if (provider.hasError) {
                  return ErrorState(
                    title: 'Failed to load events',
                    details: provider.errorMessage,
                    onRetry: () => provider.fetchEvents(),
                  );
                }

                if (provider.isBusy) {
                  return _buildLoading();
                }

                final items = provider.events;
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_busy,
                    title: 'No items found',
                    message: 'Pull to refresh or adjust filters.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.fetchEvents,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingSmall),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: MiskTheme.spacingSmall),
                    itemBuilder: (context, i) {
                      final e = items[i];
                      final dateStr = (e.eventDate?.toDate().toLocal().toString().split(' ').first) ?? '';
                      final initName = provider.initiativeNameFor(e.initiative);

                      final typeBadge = MiskBadge(label: e.type, type: _typeBadgeType(e.type), icon: Icons.category_outlined);
                      final publicBadge = e.publicVisible
                          ? const MiskBadge(label: 'Public', type: MiskBadgeType.success, icon: Icons.public)
                          : null;
                      final featuredBadge = e.featured
                          ? const MiskBadge(label: 'Featured', type: MiskBadgeType.warning, icon: Icons.star)
                          : null;
                      final dateBadge = dateStr.isNotEmpty
                          ? MiskBadge(label: dateStr, type: MiskBadgeType.neutral, icon: Icons.event)
                          : null;
                      final initBadge = e.initiative != null
                          ? MiskBadge(label: (initName == null || initName.isEmpty) ? 'Initiative' : initName, type: MiskBadgeType.info, icon: Icons.emoji_objects)
                          : null;

                      return CommonCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    e.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final ok = await const SecurityService().ensureReauthenticated(
                                      context,
                                      reason: 'Delete this item?',
                                    );
                                    if (!ok) return;
                                    try {
                                      await provider.deleteEvent(e.id);
                                      if (mounted) SnackbarHelper.showSuccess(context, 'Deleted');
                                    } catch (err) {
                                      if (mounted) SnackbarHelper.showError(context, 'Failed: $err');
                                    }
                                  },
                                ),
                              ],
                            ),
                            if ((e.description ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(e.description!),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                typeBadge,
                                if (publicBadge != null) publicBadge,
                                if (featuredBadge != null) featuredBadge,
                                if (dateBadge != null) dateBadge,
                                if (initBadge != null) initBadge,
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () async {
                                  final changed = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => EventAnnouncementFormScreen(event: e)),
                                  );
                                  if (changed == true && mounted) await provider.fetchEvents();
                                },
                                child: const Text('Edit'),
                              ),
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
            MaterialPageRoute(builder: (_) => const EventAnnouncementFormScreen()),
          );
          if (changed == true && mounted) {
            await context.read<EventAnnouncementProvider>().fetchEvents();
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
