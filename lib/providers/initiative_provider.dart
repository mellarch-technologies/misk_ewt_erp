import 'package:flutter/material.dart';
import '../models/initiative_model.dart';
import '../services/initiative_service.dart';

class InitiativeProvider extends ChangeNotifier {
  final InitiativeService _service = InitiativeService();
  List<Initiative> _all = [];
  String _filter = '';
  bool _busy = true;
  String? _errorMessage;

  // New filters
  final Set<String> _categoryFilters = {};
  bool _publicOnly = false;

  List<Initiative> get initiatives {
    Iterable<Initiative> items = _all;
    if (_filter.isNotEmpty) {
      final q = _filter;
      items = items.where((i) =>
          i.title.toLowerCase().contains(q) ||
          (i.description ?? '').toLowerCase().contains(q));
    }
    if (_categoryFilters.isNotEmpty) {
      items = items.where((i) => i.category != null && _categoryFilters.contains(i.category));
    }
    if (_publicOnly) {
      items = items.where((i) => i.publicVisible == true);
    }
    return items.toList();
  }

  bool get isBusy => _busy;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  Set<String> get categoryFilters => _categoryFilters;
  bool get publicOnly => _publicOnly;

  Future<void> fetchInitiatives() async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _all = await _service.getInitiativesOnce();
    } catch (e) {
      _errorMessage = e.toString();
      // ignore: avoid_print
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
