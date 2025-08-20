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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (v) => context.read<TaskProvider>().setFilter(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
            child: Consumer<TaskProvider>(
              builder: (_, p, __) {
                // derive statuses from current list
                final set = <String>{'All'};
                set.addAll(p.tasks.map((t) => t.status).where((e) => e.isNotEmpty));
                final statuses = set.toList();
                return Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: MiskTheme.spacingSmall),
                    const Text('My tasks'),
                    const SizedBox(width: MiskTheme.spacingXSmall),
                    Switch(
                      value: _myTasksOnly,
                      onChanged: (v) => setState(() => _myTasksOnly = v),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: MiskTheme.spacingSmall),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingSmall),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final t = items[i];
                      return ListTile(
                        title: Text(t.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((t.description ?? '').isNotEmpty) Text(t.description!),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Chip(label: Text(t.status)),
                                if (t.campaign != null)
                                  const Chip(label: Text('Campaign'), visualDensity: VisualDensity.compact),
                                if (t.initiative != null)
                                  const Chip(label: Text('Initiative'), visualDensity: VisualDensity.compact),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TaskFormScreen(task: t)),
                          );
                          if (changed == true && mounted) {
                            await provider.fetchTasks();
                          }
                        },
                        trailing: IconButton(
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
