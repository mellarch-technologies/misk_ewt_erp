// lib/screens/donations/donations_unified_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/initiative_service.dart';
import '../../services/campaign_service.dart';
import '../../models/initiative_model.dart';
import '../../models/campaign_model.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/common_card.dart';
import '../../widgets/misk_badge.dart';
import '../../widgets/search_input.dart';
import '../../widgets/state_views.dart';
import '../../widgets/snackbar_helper.dart';
import '../../theme/app_theme.dart';
import '../../services/currency_helper.dart';

class DonationsUnifiedScreen extends StatefulWidget {
  const DonationsUnifiedScreen({super.key});

  @override
  State<DonationsUnifiedScreen> createState() => _DonationsUnifiedScreenState();
}

class _DonationsUnifiedScreenState extends State<DonationsUnifiedScreen> {
  final _donationService = DonationService();
  final _searchController = TextEditingController();

  // Track by id to avoid null-valued dropdown items
  String? _selectedInitiativeId; // null = all
  String? _selectedCampaignId; // null = all

  List<Initiative> _initiatives = const [];
  List<Campaign> _campaigns = const [];

  String _method = 'All';
  String _status = 'All';
  bool _unreconciledOnly = false;

  bool _loadingFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final inits = await InitiativeService().getInitiativesOnce();
      final camps = await CampaignService().getCampaignsOnce();
      if (mounted) {
        setState(() {
          _initiatives = inits;
          _campaigns = camps;
          _loadingFilters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFilters = false);
        SnackbarHelper.showError(context, 'Failed to load filters: $e');
      }
    }
  }

  List<Campaign> _campaignsForSelectedInit() {
    if (_selectedInitiativeId == null) return _campaigns;
    return _campaigns.where((c) => c.initiative?.id == _selectedInitiativeId).toList();
  }

  List<Donation> _applyClientFilters(List<Donation> items) {
    Iterable<Donation> filtered = items;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((d) {
        final name = (d.donorName).toLowerCase();
        final ref = (d.bankRef ?? '').toLowerCase();
        return name.contains(q) || ref.contains(q);
      });
    }
    if (_method != 'All') filtered = filtered.where((d) => d.method == _method);
    if (_status != 'All') filtered = filtered.where((d) => d.status == _status);
    if (_unreconciledOnly) filtered = filtered.where((d) => !d.bankReconciled);
    return filtered.toList();
  }

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

  String? _initiativeTitle(String id) {
    final m = _initiatives.where((i) => i.id == id);
    return m.isEmpty ? null : m.first.title;
  }

  String? _campaignName(String id) {
    final m = _campaigns.where((c) => c.id == id);
    return m.isEmpty ? null : m.first.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFilters) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initiativeRef = _selectedInitiativeId == null
        ? null
        : FirebaseFirestore.instance.collection('initiatives').doc(_selectedInitiativeId);
    final campaignRef = _selectedCampaignId == null
        ? null
        : FirebaseFirestore.instance.collection('campaigns').doc(_selectedCampaignId);

    final stream = _donationService.streamDonations(
      initiative: initiativeRef,
      campaignRef: campaignRef,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Donations')),
      body: StreamProvider<List<Donation>>.value(
        value: stream,
        initialData: const [],
        catchError: (_, __) => [],
        child: Consumer<List<Donation>>(
          builder: (ctx, allItems, _) {
            final methods = _deriveMethods(allItems);
            final statuses = _deriveStatuses(allItems);
            final items = _applyClientFilters(allItems);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(MiskTheme.spacingMedium),
                  child: FilterBar(
                    children: [
                      // Initiative filter
                      SizedBox(
                        width: 320,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('init_${_selectedInitiativeId ?? ''}'),
                          isExpanded: true,
                          initialValue: _selectedInitiativeId ?? '',
                          items: [
                            const DropdownMenuItem(value: '', child: Text('All initiatives')),
                            ..._initiatives.map((i) => DropdownMenuItem(value: i.id, child: Text(i.title))).toList(),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedInitiativeId = (v == null || v.isEmpty) ? null : v;
                              // Reset campaign if it no longer matches
                              final allowed = _campaignsForSelectedInit().map((c) => c.id).toSet();
                              if (_selectedCampaignId != null && !allowed.contains(_selectedCampaignId)) {
                                _selectedCampaignId = null;
                              }
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Initiative'),
                        ),
                      ),
                      // Campaign filter (depends on initiative)
                      SizedBox(
                        width: 320,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('camp_${_selectedInitiativeId ?? ''}_${_selectedCampaignId ?? ''}'),
                          isExpanded: true,
                          initialValue: _selectedCampaignId ?? '',
                          items: [
                            const DropdownMenuItem(value: '', child: Text('All campaigns')),
                            ..._campaignsForSelectedInit().map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedCampaignId = (v == null || v.isEmpty) ? null : v;
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Campaign'),
                        ),
                      ),
                      // Search by donor name or bank ref
                      SizedBox(
                        width: 280,
                        child: SearchInput(
                          controller: _searchController,
                          hintText: 'Search donor/ref...',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      // Method
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('method_${methods.contains(_method) ? _method : 'All'}'),
                          isExpanded: true,
                          initialValue: methods.contains(_method) ? _method : 'All',
                          items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setState(() => _method = v ?? 'All'),
                          decoration: const InputDecoration(labelText: 'Method'),
                        ),
                      ),
                      // Status
                      SizedBox(
                        width: 220,
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
                            _selectedInitiativeId = null;
                            _selectedCampaignId = null;
                            _searchController.clear();
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
                                    await _donationService.quickUpdate(d.id, d.initiative, bankReconciled: true);
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
                  child: items.isEmpty
                      ? const EmptyState(
                          icon: Icons.volunteer_activism_outlined,
                          title: 'No donations found',
                          message: 'Adjust filters or try a different search.',
                        )
                      : ListView.separated(
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
                            // Initiative/Campaign badges
                            final initTitle = _initiativeTitle(d.initiative.id);
                            final campName = (d.campaign != null) ? _campaignName(d.campaign!.id) : null;
                            final initBadge = initTitle != null
                                ? MiskBadge(label: initTitle, type: MiskBadgeType.info, icon: Icons.flag_outlined)
                                : null;
                            final campBadge = campName != null
                                ? MiskBadge(label: campName, type: MiskBadgeType.neutral, icon: Icons.campaign_outlined)
                                : null;

                            return CommonCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Semantics(
                                          label: 'Donation of ${d.amount} INR from ${d.donorName}',
                                          child: Text(
                                            '${d.donorName} • ${CurrencyHelper.formatInr(d.amount)}',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: d.bankReconciled ? 'Mark unreconciled' : 'Mark reconciled',
                                            icon: Icon(d.bankReconciled ? Icons.verified_user : Icons.verified_outlined),
                                            onPressed: () async {
                                              final newVal = !d.bankReconciled;
                                              try {
                                                await _donationService.quickUpdate(
                                                  d.id,
                                                  d.initiative,
                                                  bankReconciled: newVal,
                                                );
                                                if (mounted) {
                                                  final msg = newVal ? 'Marked reconciled' : 'Marked unreconciled';
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(msg),
                                                      action: SnackBarAction(
                                                        label: 'Undo',
                                                        onPressed: () async {
                                                          try {
                                                            await _donationService.quickUpdate(
                                                              d.id,
                                                              d.initiative,
                                                              bankReconciled: !newVal,
                                                            );
                                                          } catch (_) {}
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) SnackbarHelper.showError(context, 'Failed: $e');
                                              }
                                            },
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (sel) async {
                                              if (sel == 'confirm') {
                                                try {
                                                  await _donationService.quickUpdate(d.id, d.initiative, status: 'confirmed');
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
                                                    await _donationService.quickUpdate(d.id, d.initiative, bankRef: newRef);
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
                                      if (initBadge != null) initBadge,
                                      if (campBadge != null) campBadge,
                                      methodBadge,
                                      statusBadge,
                                      reconBadge,
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
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
