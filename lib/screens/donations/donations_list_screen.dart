import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/currency_helper.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/state_views.dart';
import '../../theme/app_theme.dart';

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
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final narrow = constraints.maxWidth < 640;
              final methodField = DropdownButtonFormField<String>(
                initialValue: methods.contains(_method) ? _method : 'All',
                items: methods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _method = v ?? 'All'),
                decoration: const InputDecoration(labelText: 'Method'),
              );
              final statusField = DropdownButtonFormField<String>(
                initialValue: statuses.contains(_status) ? _status : 'All',
                items: statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'All'),
                decoration: const InputDecoration(labelText: 'Status'),
              );
              final reconSwitch = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _unreconciledOnly,
                    onChanged: (v) => setState(() => _unreconciledOnly = v),
                  ),
                  const Text('Unreconciled'),
                ],
              );

              if (narrow) {
                return Column(
                  children: [
                    methodField,
                    const SizedBox(height: MiskTheme.spacingXSmall),
                    statusField,
                    const SizedBox(height: MiskTheme.spacingXSmall),
                    Align(alignment: Alignment.centerLeft, child: reconSwitch),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: methodField),
                  const SizedBox(width: MiskTheme.spacingSmall),
                  Expanded(child: statusField),
                  const SizedBox(width: MiskTheme.spacingSmall),
                  Flexible(child: Align(alignment: Alignment.centerLeft, child: reconSwitch)),
                ],
              );
            },
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
            padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingSmall),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = items[i];
              return ListTile(
                leading: Icon(
                  d.bankReconciled ? Icons.verified : Icons.schedule,
                  color: d.bankReconciled ? Colors.green : Colors.orange,
                ),
                title: Text('${d.donorName} • ${CurrencyHelper.formatInr(d.amount)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d.method} • ${d.status}${d.bankReconciled ? ' • Reconciled' : ''}'),
                    if ((d.bankRef ?? '').isNotEmpty)
                      Text('Ref: ${d.bankRef}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Row(
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
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'confirm', child: Text('Mark Confirmed')),
                        const PopupMenuItem(value: 'edit_ref', child: Text('Edit Bank Ref/UTR')),
                      ],
                    ),
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
