import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/task_provider.dart';
import '../../providers/app_auth_provider.dart';
import '../../providers/initiative_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/state_views.dart';
import '../../widgets/snackbar_helper.dart';
import 'task_form_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_card.dart';
import '../../widgets/misk_badge.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/search_input.dart';
import '../../models/task_model.dart';
import '../../widgets/content_header.dart';
import '../../widgets/pagination_bar.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key, this.inShell = false});
  final bool inShell;

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final _searchController = TextEditingController();
  String _status = 'All';
  bool _myTasksOnly = false;
  final String _sortBy = 'Due soon'; // New sorting option
  final bool _compactView = false; // Density toggle
  int _pageIndex = 0;
  static const int _pageSize = 20;

  // Dashboard scope (persisted by DashboardScreen)
  String? _scopeInitId;
  String? _scopeCampId;
  bool _applyScope = true;
  static const _prefsInitKey = 'selected_initiative_id';
  static const _prefsCampKey = 'selected_campaign_id';

  @override
  void initState() {
    super.initState();
    // Load persisted filter states
    _loadPersistedStates();
    _loadScope();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  Future<void> _loadScope() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final init = prefs.getString(_prefsInitKey);
      final camp = prefs.getString(_prefsCampKey);
      _scopeInitId = (init != null && init.isNotEmpty) ? init : null;
      _scopeCampId = (camp != null && camp.isNotEmpty) ? camp : null;
    });
  }

  void _loadPersistedStates() {
    // Load from local storage - implement SharedPreferences later
    // For now, use default values
  }

  String _scopeLabel(BuildContext context) {
    final inits = context.read<InitiativeProvider>().initiatives;
    final camps = context.read<CampaignProvider>().campaigns;
    String initTitle;
    if (_scopeInitId == null) {
      initTitle = 'All initiatives';
    } else {
      String? title;
      for (final i in inits) {
        if (i.id == _scopeInitId) { title = i.title; break; }
      }
      initTitle = title ?? 'Initiative';
    }
    String campName = 'All campaigns';
    if (_scopeCampId != null && _scopeCampId!.isNotEmpty) {
      String? name;
      for (final c in camps) {
        if (c.id == _scopeCampId) { name = c.name; break; }
      }
      if (name != null) campName = name;
    }
    return '$initTitle • $campName';
  }

  Set<String> _campaignsForSelectedInitiative(BuildContext context) {
    final camps = context.read<CampaignProvider>().campaigns;
    final set = <String>{};
    if (_scopeInitId == null) return set;
    for (final c in camps) {
      if (c.initiative?.id == _scopeInitId) set.add(c.id);
    }
    return set;
  }

  Widget _buildEnhancedTaskCard(Task task, {bool isCompact = false}) {
    final currentUser = context.read<AppAuthProvider>().user;
    final isMyTask = task.assignedTo?.id == currentUser?.uid;

    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: SemanticColors.successGreen,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: SemanticColors.infoBlue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _markTaskComplete(task);
        } else {
          _editTask(task);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await _showCompleteConfirmation(task);
        }
        return true; // Allow edit swipe
      },
      child: CommonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.weightSemiBold,
                          decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isCompact && (task.description?.isNotEmpty == true)) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleTaskAction(task, action),
                  itemBuilder: (context) => [
                    if (task.status != 'completed')
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Mark Complete'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MiskTheme.spacingSmall),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Status badge
                MiskBadge(
                  label: task.status.toUpperCase(),
                  type: _getStatusBadgeType(task.status),
                  icon: _getStatusIcon(task.status),
                ),
                // Due date badge
                if (task.dueDate != null)
                  MiskBadge(
                    label: _formatDueDate(task.dueDate!.toDate()),
                    type: _getDueDateBadgeType(task.dueDate!.toDate()),
                    icon: Icons.schedule,
                  ),
                // Assignee badge
                if (isMyTask)
                  const MiskBadge(
                    label: 'My Task',
                    type: MiskBadgeType.info,
                    icon: Icons.person,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showCompleteConfirmation(task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Task'),
        content: Text('Mark "${task.title}" as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _markTaskComplete(task) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" completed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Implement undo logic
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to complete task: $e');
      }
    }
  }

  void _editTask(task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskFormScreen(), // Remove taskId parameter
      ),
    );
  }

  void _handleTaskAction(task, String action) async {
    switch (action) {
      case 'complete':
        _markTaskComplete(task);
        break;
      case 'edit':
        _editTask(task);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            SnackbarHelper.showSuccess(context, 'Task deleted');
          } catch (e) {
            if (mounted) {
              SnackbarHelper.showError(context, 'Failed to delete task: $e');
            }
          }
        }
        break;
    }
  }

  MiskBadgeType _getStatusBadgeType(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return MiskBadgeType.success;
      case 'in_progress':
        return MiskBadgeType.info;
      case 'pending':
        return MiskBadgeType.warning;
      case 'blocked':
        return MiskBadgeType.danger;
      default:
        return MiskBadgeType.neutral;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'pending':
        return Icons.schedule;
      case 'blocked':
        return Icons.block;
      default:
        return Icons.circle;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference <= 7) {
      return 'Due in $difference days';
    } else {
      return 'Due ${dueDate.day}/${dueDate.month}';
    }
  }

  MiskBadgeType _getDueDateBadgeType(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return MiskBadgeType.danger; // Overdue
    } else if (difference <= 1) {
      return MiskBadgeType.warning; // Due today/tomorrow
    } else {
      return MiskBadgeType.neutral; // Future dates
    }
  }

  List<dynamic> _sortTasks(List<dynamic> tasks) {
    switch (_sortBy) {
      case 'Due soon':
        return tasks..sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case 'Status':
        return tasks..sort((a, b) => a.status.compareTo(b.status));
      case 'Recently updated':
        return tasks..sort((a, b) =>
          (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
      default:
        return tasks;
    }
  }

  Widget _buildLoading() {
    // Unified skeleton loader
    return const SkeletonList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final authUid = auth.user?.uid;

    return Scaffold(
      appBar: widget.inShell ? null : AppBar(
        title: const Text('Tasks'),
      ),
      body: Column(
        children: [
          const ContentHeader(title: 'Tasks'),
          Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: SearchInput(
                    controller: _searchController,
                    hintText: 'Search tasks...',
                    onChanged: (v) {
                      context.read<TaskProvider>().setFilter(v);
                      setState(() => _pageIndex = 0);
                    },
                  ),
                ),
                const SizedBox(width: MiskTheme.spacingSmall),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingXSmall),
            child: Consumer2<TaskProvider, InitiativeProvider>(
              builder: (_, p, initProv, __) {
                final set = <String>{'All'};
                set.addAll(p.tasks.map((t) => t.status).where((e) => e.isNotEmpty));
                final statuses = set.toList();
                return FilterBar(
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextButton(
                        onPressed: () async {
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
                          if (sel != null) setState(() { _status = sel; _pageIndex = 0; });
                        },
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
                          onChanged: (v) => setState(() { _myTasksOnly = v; _pageIndex = 0; }),
                        ),
                      ],
                    ),
                    // Scope toggle and label
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Use scope'),
                        const SizedBox(width: MiskTheme.spacingXSmall),
                        Switch(
                          value: _applyScope,
                          onChanged: (v) => setState(() { _applyScope = v; _pageIndex = 0; }),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Tooltip(
                        message: _scopeLabel(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tune, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _scopeLabel(context),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _status = 'All';
                          _myTasksOnly = false;
                          _applyScope = true; // default to using scope
                          _pageIndex = 0;
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
          // Pagination (top)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
            child: Consumer3<TaskProvider, InitiativeProvider, CampaignProvider>(
              builder: (context, provider, initProv, campProv, _) {
                final allowedCampaigns = _campaignsForSelectedInitiative(context);
                // Apply local filters to determine total filtered count
                final filtered = provider.tasks.where((t) {
                  bool ok = true;
                  if (_status != 'All') ok = ok && t.status == _status;
                  if (_myTasksOnly && authUid != null) {
                    final myRef = FirebaseFirestore.instance.collection('users').doc(authUid);
                    ok = ok && t.assignedTo?.path == myRef.path;
                  }
                  if (_applyScope) {
                    if (_scopeCampId != null && _scopeCampId!.isNotEmpty) {
                      ok = ok && (t.campaign?.id == _scopeCampId);
                    } else if (_scopeInitId != null && _scopeInitId!.isNotEmpty) {
                      final matchesInit = t.initiative?.id == _scopeInitId;
                      final matchesViaCampaign = t.campaign != null && allowedCampaigns.contains(t.campaign!.id);
                      ok = ok && (matchesInit || matchesViaCampaign);
                    }
                  }
                  return ok;
                }).toList();
                final total = filtered.length;
                final pageCount = (total / _pageSize).ceil();
                final safeIndex = total == 0 ? 0 : _pageIndex.clamp(0, pageCount - 1);
                if (safeIndex != _pageIndex) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _pageIndex = safeIndex));
                return PaginationBar(
                  total: total,
                  pageSize: _pageSize,
                  pageIndex: safeIndex,
                  onPageChanged: (p) => setState(() => _pageIndex = p),
                );
              },
            ),
          ),
          const SizedBox(height: MiskTheme.spacingXSmall),
          Expanded(
            child: Consumer3<TaskProvider, InitiativeProvider, CampaignProvider>(
              builder: (context, provider, initProv, campProv, _) {
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

                final allowedCampaigns = _campaignsForSelectedInitiative(context);
                // Local filtering: status + my tasks + scope
                final filtered = provider.tasks.where((t) {
                  bool ok = true;
                  if (_status != 'All') ok = ok && t.status == _status;
                  if (_myTasksOnly && authUid != null) {
                    final myRef = FirebaseFirestore.instance.collection('users').doc(authUid);
                    ok = ok && t.assignedTo?.path == myRef.path;
                  }
                  if (_applyScope) {
                    if (_scopeCampId != null && _scopeCampId!.isNotEmpty) {
                      ok = ok && (t.campaign?.id == _scopeCampId);
                    } else if (_scopeInitId != null && _scopeInitId!.isNotEmpty) {
                      final matchesInit = t.initiative?.id == _scopeInitId;
                      final matchesViaCampaign = t.campaign != null && allowedCampaigns.contains(t.campaign!.id);
                      ok = ok && (matchesInit || matchesViaCampaign);
                    }
                  }
                  return ok;
                }).toList();

                // Sort tasks based on the selected criteria
                final sortedItems = _sortTasks(filtered);

                if (sortedItems.isEmpty) {
                  return const EmptyState(
                    icon: Icons.task_alt_outlined,
                    title: 'No tasks found',
                    message: 'Pull to refresh or adjust filters.',
                  );
                }

                // Pagination slice
                final total = sortedItems.length;
                final pageCount = (total / _pageSize).ceil();
                final safeIndex = total == 0 ? 0 : _pageIndex.clamp(0, pageCount - 1);
                final start = safeIndex * _pageSize;
                final end = (start + _pageSize) > total ? total : (start + _pageSize);
                final visible = sortedItems.sublist(start, end);

                return RefreshIndicator(
                  onRefresh: provider.fetchTasks,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingSmall),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: MiskTheme.spacingSmall),
                    itemBuilder: (ctx, i) {
                      final t = visible[i];
                      return _buildEnhancedTaskCard(t, isCompact: _compactView);
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
