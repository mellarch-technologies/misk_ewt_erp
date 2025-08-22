import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/task_provider.dart';
import '../../providers/app_auth_provider.dart';
import '../../widgets/state_views.dart';
import '../../services/security_service.dart';
import '../../widgets/snackbar_helper.dart';
import 'task_form_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_card.dart';
import '../../widgets/misk_badge.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/search_input.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final _searchController = TextEditingController();
  String _status = 'All';
  bool _myTasksOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  Widget _buildLoading() {
    // Unified skeleton loader
    return const SkeletonList();
  }

  Future<void> _pickStatus(List<String> statuses) async {
    final sel = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: statuses
              .map((s) => ListTile(title: Text(s), onTap: () => Navigator.pop(ctx, s)))
              .toList(),
        ),
      ),
    );
    if (sel != null) setState(() => _status = sel);
  }

  MiskBadgeType _statusBadgeType(String s) {
    final v = s.toLowerCase();
    if (v.contains('done') || v.contains('completed')) return MiskBadgeType.success;
    if (v.contains('progress') || v.contains('doing')) return MiskBadgeType.info;
    if (v.contains('block') || v.contains('hold')) return MiskBadgeType.danger;
    if (v.contains('pending') || v.contains('todo')) return MiskBadgeType.warning;
    return MiskBadgeType.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final authUid = auth.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tasks'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: SearchInput(
              controller: _searchController,
              hintText: 'Search tasks...',
              onChanged: (v) => context.read<TaskProvider>().setFilter(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingXSmall),
            child: Consumer<TaskProvider>(
              builder: (_, p, __) {
                // derive statuses from current list
                final set = <String>{'All'};
                set.addAll(p.tasks.map((t) => t.status).where((e) => e.isNotEmpty));
                final statuses = set.toList();
                return FilterBar(
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextButton(
                        onPressed: () => _pickStatus(statuses),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list),
                            const SizedBox(width: MiskTheme.spacingXSmall),
                            Expanded(
                              child: Text(
                                'Status: ${statuses.contains(_status) ? _status : 'All'}',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('My tasks'),
                        const SizedBox(width: MiskTheme.spacingXSmall),
                        Switch(
                          value: _myTasksOnly,
                          onChanged: (v) => setState(() => _myTasksOnly = v),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _status = 'All';
                          _myTasksOnly = false;
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear'),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: MiskTheme.spacingXSmall),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                if (provider.hasError) {
                  return ErrorState(
                    title: 'Failed to load tasks',
                    details: provider.errorMessage,
                    onRetry: () => provider.fetchTasks(),
                  );
                }

                if (provider.isBusy) {
                  return _buildLoading();
                }

                // Local filtering: status + my tasks
                final items = provider.tasks.where((t) {
                  bool ok = true;
                  if (_status != 'All') ok = ok && t.status == _status;
                  if (_myTasksOnly && authUid != null) {
                    final myRef = FirebaseFirestore.instance.collection('users').doc(authUid);
                    ok = ok && t.assignedTo?.path == myRef.path;
                  }
                  return ok;
                }).toList();

                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.task_alt_outlined,
                    title: 'No tasks found',
                    message: 'Pull to refresh or adjust filters.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.fetchTasks,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingSmall),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: MiskTheme.spacingSmall),
                    itemBuilder: (ctx, i) {
                      final t = items[i];
                      final statusBadge = MiskBadge(label: t.status.isEmpty ? 'Status' : t.status, type: _statusBadgeType(t.status), icon: Icons.flag);
                      final campaignBadge = t.campaign != null
                          ? const MiskBadge(label: 'Campaign', type: MiskBadgeType.info, icon: Icons.campaign)
                          : null;
                      final initiativeBadge = t.initiative != null
                          ? const MiskBadge(label: 'Initiative', type: MiskBadgeType.neutral, icon: Icons.emoji_objects)
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
                                    t.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final ok = await const SecurityService().ensureReauthenticated(
                                      context,
                                      reason: 'Delete this task?',
                                    );
                                    if (!ok) return;
                                    try {
                                      await provider.deleteTask(t.id);
                                      if (mounted) SnackbarHelper.showSuccess(context, 'Task deleted');
                                    } catch (e) {
                                      if (mounted) SnackbarHelper.showError(context, 'Failed: $e');
                                    }
                                  },
                                ),
                              ],
                            ),
                            if ((t.description ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(t.description!),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                statusBadge,
                                if (campaignBadge != null) campaignBadge,
                                if (initiativeBadge != null) initiativeBadge,
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () async {
                                  final changed = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TaskFormScreen(task: t)),
                                  );
                                  if (changed == true && mounted) {
                                    await provider.fetchTasks();
                                  }
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
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          if (changed == true && mounted) {
            await context.read<TaskProvider>().fetchTasks();
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
