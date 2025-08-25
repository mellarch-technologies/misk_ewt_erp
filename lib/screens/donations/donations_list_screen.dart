import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/currency_helper.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/state_views.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_card.dart';
import '../../widgets/misk_badge.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/pagination_bar.dart';

class DonationsListScreen extends StatelessWidget {
  final DocumentReference initiativeRef;
  final DocumentReference? campaignRef;
  const DonationsListScreen({super.key, required this.initiativeRef, this.campaignRef});

  @override
  Widget build(BuildContext context) {
    final service = DonationService();
    return Scaffold(
      appBar: AppBar(title: Text(campaignRef == null ? 'Donations' : 'Donations · Campaign')),
      body: StreamProvider<List<Donation>>.value(
        value: service.streamDonations(initiative: initiativeRef, campaignRef: campaignRef),
        initialData: const [],
        catchError: (_, __) => [],
        child: _DonationsBody(initiativeRef: initiativeRef, service: service, campaignRef: campaignRef),
      ),
    );
  }
}

class _DonationsBody extends StatefulWidget {
  final DocumentReference initiativeRef;
  final DocumentReference? campaignRef;
  final DonationService service;
  const _DonationsBody({required this.initiativeRef, required this.service, this.campaignRef});

  @override
  State<_DonationsBody> createState() => _DonationsBodyState();
}

class _DonationsBodyState extends State<_DonationsBody> {
  String _method = 'All';
  String _status = 'All';
  bool _unreconciledOnly = false;
  DateTimeRange? _range;
  int _pageIndex = 0;
  static const int _pageSize = 20;

  List<String> _deriveMethods(List<Donation> items) {
    final s = <String>{'All'};
    s.addAll(items.map((e) => e.method).where((e) => e.isNotEmpty));
    return s.toList();
  }

  List<String> _deriveStatuses(List<Donation> items) {
    final s = <String>{'All'};
    s.addAll(items.map((e) => e.status).where((e) => e.isNotEmpty));
    return s.toList();
  }

  bool _inRange(Donation d) {
    if (_range == null) return true;
    final when = (d.receivedAt ?? d.createdAt)?.toDate();
    if (when == null) return false;
    final s = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
    final e = DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59, 999);
    return !when.isBefore(s) && !when.isAfter(e);
  }

  List<Widget> _activeFilterChips() {
    final chips = <Widget>[];
    if (_method != 'All') {
      chips.add(_chip('Method: $_method', () => setState(() { _method = 'All'; _pageIndex = 0; })));
    }
    if (_status != 'All') {
      chips.add(_chip('Status: $_status', () => setState(() { _status = 'All'; _pageIndex = 0; })));
    }
    if (_unreconciledOnly) {
      chips.add(_chip('Unreconciled', () => setState(() { _unreconciledOnly = false; _pageIndex = 0; })));
    }
    if (_range != null) {
      final s = '${_range!.start.year}-${_range!.start.month.toString().padLeft(2, '0')}-${_range!.start.day.toString().padLeft(2, '0')}';
      final e = '${_range!.end.year}-${_range!.end.month.toString().padLeft(2, '0')}-${_range!.end.day.toString().padLeft(2, '0')}';
      chips.add(_chip('Date: $s → $e', () => setState(() { _range = null; _pageIndex = 0; })));
    }
    return chips;
  }

  Widget _chip(String label, VoidCallback onDeleted) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = Provider.of<List<Donation>>(context);
    if (allItems.isEmpty) {
      return const EmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'No donations yet',
        message: 'New donations will appear here as they are added.',
      );
    }

    final methods = _deriveMethods(allItems);
    final statuses = _deriveStatuses(allItems);

    Iterable<Donation> filtered = allItems;
    if (_method != 'All') filtered = filtered.where((d) => d.method == _method);
    if (_status != 'All') filtered = filtered.where((d) => d.status == _status);
    if (_unreconciledOnly) filtered = filtered.where((d) => !d.bankReconciled);
    filtered = filtered.where(_inRange);
    final filteredList = filtered.toList();

    // Pagination slice over filtered list
    final total = filteredList.length;
    final pageCount = (total / _pageSize).ceil();
    final safeIndex = total == 0 ? 0 : _pageIndex.clamp(0, pageCount - 1);
    final start = safeIndex * _pageSize;
    final end = (start + _pageSize) > total ? total : (start + _pageSize);
    final items = filteredList.sublist(start, end);

    return Column(
      children: [
        if (widget.campaignRef != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MiskTheme.spacingMedium,
              MiskTheme.spacingSmall,
              MiskTheme.spacingMedium,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Filtered by campaign', style: TextStyle(color: Colors.grey.shade700)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MiskTheme.spacingMedium,
            MiskTheme.spacingXSmall,
            MiskTheme.spacingMedium,
            MiskTheme.spacingXSmall,
          ),
          child: FilterBar(
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('method_${methods.contains(_method) ? _method : 'All'}'),
                  isExpanded: true,
                  initialValue: methods.contains(_method) ? _method : 'All',
                  items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() { _method = v ?? 'All'; _pageIndex = 0; }),
                  decoration: const InputDecoration(labelText: 'Method'),
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('status_${statuses.contains(_status) ? _status : 'All'}'),
                  isExpanded: true,
                  initialValue: statuses.contains(_status) ? _status : 'All',
                  items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() { _status = v ?? 'All'; _pageIndex = 0; }),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(value: _unreconciledOnly, onChanged: (v) => setState(() { _unreconciledOnly = v; _pageIndex = 0; })),
                  const Text('Unreconciled'),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
                  );
                  if (picked != null) setState(() { _range = picked; _pageIndex = 0; });
                },
                icon: const Icon(Icons.date_range),
                label: Text(_range == null ? 'Date range' : 'Change date'),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _method = 'All';
                    _status = 'All';
                    _unreconciledOnly = false;
                    _range = null;
                    _pageIndex = 0;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        if (_activeFilterChips().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MiskTheme.spacingMedium,
              0,
              MiskTheme.spacingMedium,
              MiskTheme.spacingXSmall,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 6, runSpacing: 6, children: _activeFilterChips()),
            ),
          ),
        // Pagination bar (top)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
          child: PaginationBar(
            total: total,
            pageSize: _pageSize,
            pageIndex: _pageIndex.clamp(0, (total / _pageSize).ceil() > 0 ? (total / _pageSize).ceil() - 1 : 0),
            onPageChanged: (p) => setState(() => _pageIndex = p),
          ),
        ),
        // Summary + Bulk action row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
          child: Row(
            children: [
              Expanded(
                child: Text('Filtered: $total of ${allItems.length}', style: TextStyle(color: Colors.grey.shade700)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.task_alt_outlined),
                label: const Text('Mark page reconciled'),
                onPressed: items.any((d) => !d.bankReconciled)
                    ? () async {
                        final targets = items.where((d) => !d.bankReconciled).toList();
                        final count = targets.length;
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm page reconcile'),
                            content: Text('Mark $count donation(s) on this page as bank reconciled?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          try {
                            for (final d in targets) {
                              await widget.service.quickUpdate(d.id, d.initiative, bankReconciled: true);
                            }
                            if (!mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Reconciled $count donation(s) on this page'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () async {
                                    for (final d in targets) {
                                      await widget.service.quickUpdate(d.id, d.initiative, bankReconciled: false);
                                    }
                                    if (mounted) SnackbarHelper.showInfo(context, 'Undo applied');
                                  },
                                ),
                              ),
                            );
                          } catch (e) {
                            if (mounted) SnackbarHelper.showError(context, 'Failed: $e');
                          }
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingSmall),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: MiskTheme.spacingSmall),
            itemBuilder: (ctx, i) {
              final d = items[i];
              final methodBadge = MiskBadge(label: d.method.isEmpty ? 'Method' : d.method, type: MiskBadgeType.neutral, icon: Icons.payment);
              final statusType = d.status == 'confirmed'
                  ? MiskBadgeType.success
                  : (d.status == 'pending' ? MiskBadgeType.warning : MiskBadgeType.neutral);
              final statusBadge = MiskBadge(label: d.status.isEmpty ? 'Status' : d.status, type: statusType, icon: Icons.verified);
              final reconBadge = d.bankReconciled
                  ? const MiskBadge(label: 'Bank Reconciled', type: MiskBadgeType.success, icon: Icons.verified_user)
                  : const MiskBadge(label: 'Unreconciled', type: MiskBadgeType.warning, icon: Icons.history);

              final when = (d.receivedAt ?? d.createdAt)?.toDate();
              final dateText = when == null
                  ? ''
                  : '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';

              return CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${d.donorName} • ${CurrencyHelper.formatInr(d.amount)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: d.bankReconciled ? 'Mark unreconciled' : 'Mark reconciled',
                              icon: Icon(d.bankReconciled ? Icons.verified_user : Icons.verified_outlined),
                              onPressed: () async {
                                try {
                                  await widget.service.quickUpdate(
                                    d.id,
                                    d.initiative,
                                    bankReconciled: !d.bankReconciled,
                                  );
                                  if (mounted) SnackbarHelper.showSuccess(context, d.bankReconciled ? 'Marked unreconciled' : 'Marked reconciled');
                                } catch (e) {
                                  if (mounted) SnackbarHelper.showError(context, 'Failed: $e');
                                }
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (sel) async {
                                if (sel == 'confirm') {
                                  try {
                                    await widget.service.quickUpdate(d.id, d.initiative, status: 'confirmed');
                                    if (mounted) SnackbarHelper.showSuccess(context, 'Marked confirmed');
                                  } catch (e) {
                                    if (mounted) SnackbarHelper.showError(context, 'Failed: $e');
                                  }
                                } else if (sel == 'edit_ref') {
                                  final controller = TextEditingController(text: d.bankRef ?? '');
                                  final newRef = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Edit Bank Ref / UTR'),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(hintText: 'Enter bank ref / UTR'),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
                                      ],
                                    ),
                                  );
                                  if (newRef != null) {
                                    try {
                                      await widget.service.quickUpdate(d.id, d.initiative, bankRef: newRef);
                                      if (mounted) SnackbarHelper.showSuccess(context, 'Reference updated');
                                    } catch (e) {
                                      if (mounted) SnackbarHelper.showError(context, 'Failed: $e');
                                    }
                                  }
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(value: 'confirm', child: Text('Mark Confirmed')),
                                PopupMenuItem(value: 'edit_ref', child: Text('Edit Bank Ref/UTR')),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        methodBadge,
                        statusBadge,
                        reconBadge,
                        if (dateText.isNotEmpty)
                          MiskBadge(label: dateText, type: MiskBadgeType.neutral, icon: Icons.event),
                      ],
                    ),
                    if ((d.bankRef ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Ref: ${d.bankRef}', style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
