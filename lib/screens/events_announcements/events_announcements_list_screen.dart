import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_announcement_provider.dart';
import '../../widgets/state_views.dart';
import '../../services/security_service.dart';
import '../../widgets/snackbar_helper.dart';
import 'event_announcement_form_screen.dart';
import '../../widgets/back_or_home_button.dart';
import '../../theme/app_theme.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: p.typeFilter,
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => p.setTypeFilter(v ?? 'All'),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ),
          const SizedBox(width: MiskTheme.spacingSmall),
          Row(children: [
            Switch(value: p.publicOnly, onChanged: p.setPublicOnly),
            const Text('Public only'),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events & Announcements'), leading: const BackOrHomeButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events & announcements...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (v) => context.read<EventAnnouncementProvider>().setFilter(v),
            ),
          ),
          Consumer<EventAnnouncementProvider>(builder: (_, p, __) => _filters(p)),
          const SizedBox(height: MiskTheme.spacingSmall),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingSmall),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final e = items[i];
                      final dateStr = (e.eventDate?.toDate().toLocal().toString().split(' ').first) ?? '';
                      final initName = provider.initiativeNameFor(e.initiative);
                      return ListTile(
                        title: Text(e.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((e.description ?? '').isNotEmpty) Text(e.description!),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Chip(label: Text(e.type)),
                                if (e.publicVisible)
                                  const Chip(label: Text('Public'), visualDensity: VisualDensity.compact),
                                if (e.featured)
                                  Chip(label: const Text('Featured'), visualDensity: VisualDensity.compact, side: BorderSide(color: Colors.amber)),
                                if (dateStr.isNotEmpty)
                                  Chip(label: Text(dateStr), visualDensity: VisualDensity.compact),
                                if (e.initiative != null)
                                  Chip(
                                    label: Text((initName == null || initName.isEmpty) ? 'Initiative' : initName),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EventAnnouncementFormScreen(event: e)),
                          );
                          if (changed == true && mounted) await provider.fetchEvents();
                        },
                        trailing: IconButton(
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
