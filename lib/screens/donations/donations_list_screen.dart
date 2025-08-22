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
    // When campaignRef is set, items are already filtered at the query-layer; we still allow local filters
    if (_method != 'All') filtered = filtered.where((d) => d.method == _method);
    if (_status != 'All') filtered = filtered.where((d) => d.status == _status);
    if (_unreconciledOnly) filtered = filtered.where((d) => !d.bankReconciled);
    final items = filtered.toList();

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
                  onChanged: (v) => setState(() => _method = v ?? 'All'),
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
                  onChanged: (v) => setState(() => _status = v ?? 'All'),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(value: _unreconciledOnly, onChanged: (v) => setState(() => _unreconciledOnly = v)),
                  const Text('Unreconciled'),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _method = 'All';
                    _status = 'All';
                    _unreconciledOnly = false;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        // Bulk action row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.task_alt_outlined),
              label: const Text('Mark filtered reconciled'),
              onPressed: items.any((d) => !d.bankReconciled)
                  ? () async {
                      final count = items.where((d) => !d.bankReconciled).length;
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm bulk reconcile'),
                          content: Text('Mark $count donation(s) as bank reconciled?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        try {
                          for (final d in items.where((d) => !d.bankReconciled)) {
                            await widget.service.quickUpdate(d.id, d.initiative, bankReconciled: true);
                          }
                          if (mounted) SnackbarHelper.showSuccess(context, 'Reconciled $count donation(s)');
                        } catch (e) {
                          if (mounted) SnackbarHelper.showError(context, 'Failed: $e');
                        }
                      }
                    }
                  : null,
            ),
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
                      children: [methodBadge, statusBadge, reconBadge],
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
