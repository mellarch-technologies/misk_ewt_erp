// lib/screens/donations/donations_unified_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/initiative_service.dart';
import '../../services/campaign_service.dart';
import '../../models/initiative_model.dart';
import '../../models/campaign_model.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/common_card.dart';
import '../../widgets/search_input.dart';
import '../../widgets/snackbar_helper.dart';
import '../../theme/app_theme.dart';
import '../../services/currency_helper.dart';
import '../../widgets/content_header.dart';

class DonationsUnifiedScreen extends StatefulWidget {
  const DonationsUnifiedScreen({super.key, this.inShell = false});
  final bool inShell;

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

  // Server-side date range and pagination
  Timestamp? _startTs;
  Timestamp? _endTs;
  final int _pageSize = 20;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingPage = false;
  bool _initialLoading = true;
  List<Donation> _items = [];

  String _method = 'All';
  String _status = 'All';
  bool _unreconciledOnly = false;

  bool _loadingFilters = true;

  final ScrollController _scrollController = ScrollController();
  bool _filtersSticky = false;
  int _resultCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFilters();

    _scrollController.addListener(() {
      final shouldBeSticky = _scrollController.offset > 8;
      if (shouldBeSticky != _filtersSticky) {
        setState(() => _filtersSticky = shouldBeSticky);
      }
    });
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
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFilters = false);
        SnackbarHelper.showError(context, 'Failed to load filters: $e');
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items = [];
      _lastDoc = null;
      _hasMore = true;
      _initialLoading = true;
    });
    await _loadNextPage();
    if (mounted) setState(() => _initialLoading = false);
  }

  DocumentReference? _initiativeRefOrNull() =>
      _selectedInitiativeId == null ? null : FirebaseFirestore.instance.collection('initiatives').doc(_selectedInitiativeId);
  DocumentReference? _campaignRefOrNull() =>
      _selectedCampaignId == null ? null : FirebaseFirestore.instance.collection('campaigns').doc(_selectedCampaignId);

  Future<void> _loadNextPage() async {
    if (!_hasMore || _loadingPage) return;
    setState(() => _loadingPage = true);
    try {
      final page = await _donationService.getDonationsPage(
        initiative: _initiativeRefOrNull(),
        campaignRef: _campaignRefOrNull(),
        startDate: _startTs,
        endDate: _endTs,
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      setState(() {
        _items.addAll(page.items);
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Failed to load donations: $e');
      setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _loadingPage = false);
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final initialStart = _startTs?.toDate() ?? DateTime(now.year, now.month, 1);
    final initialEnd = _endTs?.toDate() ?? now;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked != null) {
      // Normalize to full-day bounds
      final st = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
      final en = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      setState(() {
        _startTs = Timestamp.fromDate(st);
        _endTs = Timestamp.fromDate(en);
      });
      await _refresh();
    }
  }

  String _dateRangeLabel() {
    if (_startTs == null && _endTs == null) return 'Date range';
    final st = _startTs?.toDate();
    final en = _endTs?.toDate();
    String fmt(DateTime d) => d.toLocal().toString().split(' ').first;
    if (st != null && en != null) return '${fmt(st)} → ${fmt(en)}';
    if (st != null) return '${fmt(st)} →';
    if (en != null) return '… → ${fmt(en)}';
    return 'Date range';
  }

  void _clearAllFilters() {
    setState(() {
      _selectedInitiativeId = null;
      _selectedCampaignId = null;
      _method = 'All';
      _status = 'All';
      _unreconciledOnly = false;
      _searchController.clear();
    });
    _refresh();
  }

  // Helper methods
  String _getInitiativeName(String id) {
    final match = _initiatives.where((i) => i.id == id);
    return match.isNotEmpty ? match.first.title : 'Unknown Initiative';
  }

  String _getCampaignName(String id) {
    final match = _campaigns.where((c) => c.id == id);
    return match.isNotEmpty ? match.first.name : 'Unknown Campaign';
  }

  Future<void> _onSearchChanged(String value) async {
    setState(() {});
    // Debounce search to avoid excessive rebuilds
    await Future.delayed(const Duration(milliseconds: 300));
    final results = _applyClientFilters(_items);
    setState(() => _resultCount = results.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFilters || _initialLoading) {
      return Scaffold(
        appBar: widget.inShell ? null : AppBar(title: const Text('Donations')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final methods = _deriveMethods(_items);
    final statuses = _deriveStatuses(_items);
    final items = _applyClientFilters(_items);

    return Scaffold(
      appBar: widget.inShell ? null : AppBar(title: const Text('Donations')),
      body: Column(
        children: [
          const ContentHeader(title: 'Donations'),
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
                    onChanged: (v) async {
                      setState(() {
                        _selectedInitiativeId = (v == null || v.isEmpty) ? null : v;
                        // Reset campaign if it no longer matches
                        final allowed = _campaignsForSelectedInit().map((c) => c.id).toSet();
                        if (_selectedCampaignId != null && !allowed.contains(_selectedCampaignId)) {
                          _selectedCampaignId = null;
                        }
                      });
                      await _refresh();
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
                    onChanged: (v) async {
                      setState(() {
                        _selectedCampaignId = (v == null || v.isEmpty) ? null : v;
                      });
                      await _refresh();
                    },
                    decoration: const InputDecoration(labelText: 'Campaign'),
                  ),
                ),
                // Date range picker
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateRangeLabel()),
                ),
                if (_startTs != null || _endTs != null)
                  TextButton.icon(
                    onPressed: () async {
                      setState(() { _startTs = null; _endTs = null; });
                      await _refresh();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear dates'),
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
                    isExpanded: true,
                    initialValue: statuses.contains(_status) ? _status : 'All',
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _status = v ?? 'All'),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ),
                // Unreconciled only
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: _unreconciledOnly, onChanged: (v) => setState(() => _unreconciledOnly = v)),
                    const Text('Unreconciled only'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingMedium, vertical: MiskTheme.spacingSmall),
                itemCount: items.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: MiskTheme.spacingSmall),
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    _loadNextPage();
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  }
                  final d = items[index];
                  return CommonCard(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: d.bankReconciled ? MiskTheme.donationGreen.withValues(alpha: 0.2) : MiskTheme.accentGold.withValues(alpha: 0.2),
                        child: Icon(d.bankReconciled ? Icons.verified : Icons.schedule, color: d.bankReconciled ? MiskTheme.donationGreen : MiskTheme.accentGold),
                      ),
                      title: Text('${CurrencyHelper.formatInr(d.amount)} • ${d.method}'),
                      subtitle: Text([d.donorName, d.status, d.bankRef ?? ''].where((e) => e.isNotEmpty).join(' • ')),
                      trailing: d.bankReconciled ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
