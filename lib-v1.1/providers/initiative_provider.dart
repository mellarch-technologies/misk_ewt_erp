import 'package:flutter/material.dart';
import '../models/initiative_model.dart';
import '../services/initiative_service.dart';

class InitiativeProvider extends ChangeNotifier {
  final InitiativeService _service = InitiativeService();
  List<Initiative> _all = [];
  String _filter = '';
  bool _busy = true;

  List<Initiative> get initiatives => _filter.isEmpty
      ? _all
      : _all.where((i) => i.title.toLowerCase().contains(_filter)).toList();

  bool get isBusy => _busy;

  Future<void> fetchInitiatives() async {
    _busy = true;
    notifyListeners();
    try {
      _all = await _service.getInitiativesOnce();
    } catch (e) {
      print("Error fetching initiatives: $e");
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> saveInitiative(Initiative i) async {
    if (i.id.isEmpty) {
      await _service.addInitiative(i);
    } else {
      await _service.updateInitiative(i);
    }
    await fetchInitiatives();
  }

  Future<void> deleteInitiative(String id) async {
    await _service.deleteInitiative(id);
    await fetchInitiatives();
  }
}

