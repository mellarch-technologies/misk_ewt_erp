import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/initiative_provider.dart';
import '../../widgets/state_views.dart';
import 'initiative_form_screen.dart';
import '../../widgets/initiative_card.dart';
import 'initiative_detail_screen.dart';
import '../../widgets/back_or_home_button.dart';
import '../../theme/app_theme.dart';

class InitiativesListScreen extends StatefulWidget {
  const InitiativesListScreen({super.key});

  @override
  State<InitiativesListScreen> createState() => _InitiativesListScreenState();
}

class _InitiativesListScreenState extends State<InitiativesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InitiativeProvider>().fetchInitiatives();
    });
  }

  Widget _buildLoading() {
    // Use shared skeletons for a consistent loading state
    return const SkeletonList();
  }

  Widget _buildFilters(BuildContext context, InitiativeProvider provider) {
    // Build category set from current items; fallback to common set if empty
    final cats = <String>{}
      ..addAll(provider.initiatives.map((e) => e.category).whereType<String>().where((c) => c.isNotEmpty));
    if (cats.isEmpty) {
      cats.addAll(['infrastructure', 'education', 'health', 'community', 'relief', 'other']);
    }

    return Column(
      children: [
        // Category chips
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
        // Public-only toggle
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
      appBar: AppBar(title: const Text('Initiatives'), leading: const BackOrHomeButton()),
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
                hintText: 'Search initiatives...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (v) => context.read<InitiativeProvider>().setFilter(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
            child: Consumer<InitiativeProvider>(
              builder: (context, provider, _) => _buildFilters(context, provider),
            ),
          ),
          const SizedBox(height: MiskTheme.spacingSmall),
          Expanded(
            child: Consumer<InitiativeProvider>(
              builder: (context, provider, _) {
                if (provider.hasError) {
                  return ErrorState(
                    title: 'Failed to load initiatives',
                    details: provider.errorMessage,
                    onRetry: () => provider.fetchInitiatives(),
                  );
                }

                if (provider.isBusy) {
                  return _buildLoading();
                }

                final items = provider.initiatives;
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'No initiatives found',
                    message: 'Pull to refresh or add a new initiative.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.fetchInitiatives,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount = 1;
                      if (width >= 1200) crossAxisCount = 4;
                      else if (width >= 900) crossAxisCount = 3;
                      else if (width >= 600) crossAxisCount = 2;

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MiskTheme.spacingSmall,
                          vertical: MiskTheme.spacingSmall,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: MiskTheme.spacingSmall,
                          mainAxisSpacing: MiskTheme.spacingSmall,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: provider.initiatives.length,
                        itemBuilder: (context, i) {
                          final initiative = items[i];
                          return InitiativeCard(
                            initiative: initiative,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InitiativeDetailScreen(initiative: initiative),
                                ),
                              );
                              // No refresh needed for view-only
                            },
                            onEdit: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InitiativeFormScreen(initiative: initiative),
                                ),
                              );
                              if (changed == true) {
                                await provider.fetchInitiatives();
                              }
                            },
                          );
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
          final changed = await Navigator.pushNamed(context, '/initiatives/form');
          if (changed == true && mounted) {
            await context.read<InitiativeProvider>().fetchInitiatives();
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
