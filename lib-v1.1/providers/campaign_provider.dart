import 'package:flutter/material.dart';
import '../models/campaign_model.dart';
import '../services/campaign_service.dart';

class CampaignProvider extends ChangeNotifier {
  final CampaignService _service = CampaignService();
  List<Campaign> _all = [];
  String _filter = '';
  bool _busy = true;

  List<Campaign> get campaigns => _filter.isEmpty
      ? _all
      : _all.where((c) => c.name.toLowerCase().contains(_filter)).toList();

  bool get isBusy => _busy;

  Future<void> fetchCampaigns() async {
    _busy = true;
    notifyListeners();
    try {
      _all = await _service.getCampaignsOnce();
    } catch (e) {
      print("Error fetching campaigns: $e");
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
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

