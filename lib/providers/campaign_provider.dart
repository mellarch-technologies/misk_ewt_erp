import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campaign_model.dart';
import '../services/campaign_service.dart';

class CampaignProvider extends ChangeNotifier {
  final CampaignService _service = CampaignService();
  List<Campaign> _all = [];
  String _filter = '';
  bool _busy = true;
  String? _errorMessage;

  // New filters
  final Set<String> _categoryFilters = {};
  bool _publicOnly = false;

  // New: initiative id -> title cache for list chips
  final Map<String, String> _initiativeNames = {};

  List<Campaign> get campaigns {
    Iterable<Campaign> items = _all;
    if (_filter.isNotEmpty) {
      final q = _filter;
      items = items.where((c) =>
          c.name.toLowerCase().contains(q) || (c.description ?? '').toLowerCase().contains(q));
    }
    if (_categoryFilters.isNotEmpty) {
      items = items.where((c) => c.category != null && _categoryFilters.contains(c.category));
    }
    if (_publicOnly) {
      items = items.where((c) => c.publicVisible == true);
    }
    return items.toList();
  }

  bool get isBusy => _busy;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  Set<String> get categoryFilters => _categoryFilters;
  bool get publicOnly => _publicOnly;

  // Expose initiative title for a given ref
  String? initiativeNameFor(DocumentReference? ref) => ref == null ? null : _initiativeNames[ref.id];

  Future<void> fetchCampaigns() async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _all = await _service.getCampaignsOnce();
      await _preloadInitiatives();
    } catch (e) {
      _errorMessage = e.toString();
      // ignore: avoid_print
      print("Error fetching campaigns: $e");
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _preloadInitiatives() async {
    // Collect unique initiative ids from campaigns
    final ids = <String>{};
    for (final c in _all) {
      final ref = c.initiative;
      if (ref != null && !_initiativeNames.containsKey(ref.id)) {
        ids.add(ref.id);
      }
    }
    if (ids.isEmpty) return;
    try {
      final futures = ids.map((id) async {
        final doc = await FirebaseFirestore.instance.collection('initiatives').doc(id).get();
        final data = doc.data();
        if (data != null) {
          _initiativeNames[id] = (data['title'] as String?) ?? 'Initiative';
        }
      });
      await Future.wait(futures);
    } catch (e) {
      // ignore errors; fallback chip will show generic label
      // ignore: avoid_print
      print('Failed to preload initiative names: $e');
    }
    notifyListeners();
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (_categoryFilters.contains(category)) {
      _categoryFilters.remove(category);
    } else {
      _categoryFilters.add(category);
    }
    notifyListeners();
  }

  void setPublicOnly(bool value) {
    _publicOnly = value;
    notifyListeners();
  }

  Future<void> saveCampaign(Campaign c) async {
    if (c.id.isEmpty) {
      await _service.addCampaign(c);
    } else {
      await _service.updateCampaign(c);
    }
    await fetchCampaigns();
  }

  Future<void> deleteCampaign(String id) async {
    await _service.deleteCampaign(id);
    await fetchCampaigns();
  }
}
