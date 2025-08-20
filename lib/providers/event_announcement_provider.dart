import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_announcement_model.dart';
import '../services/event_announcement_service.dart';

class EventAnnouncementProvider extends ChangeNotifier {
  final EventAnnouncementService _service = EventAnnouncementService();
  List<EventAnnouncement> _all = [];
  String _filter = '';
  String _typeFilter = 'All'; // 'All' | 'event' | 'announcement'
  bool _publicOnly = false;
  bool _busy = true;
  String? _errorMessage;
  // Initiative id -> title cache
  final Map<String, String> _initiativeNames = {};

  List<EventAnnouncement> get events {
    Iterable<EventAnnouncement> items = _all;
    if (_filter.isNotEmpty) {
      final q = _filter;
      items = items.where((e) => e.title.toLowerCase().contains(q) || (e.description ?? '').toLowerCase().contains(q));
    }
    if (_typeFilter != 'All') {
      items = items.where((e) => e.type == _typeFilter);
    }
    if (_publicOnly) {
      items = items.where((e) => e.publicVisible == true);
    }
    return items.toList();
  }

  bool get isBusy => _busy;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String get typeFilter => _typeFilter;
  bool get publicOnly => _publicOnly;

  // Expose initiative title for a given ref
  String? initiativeNameFor(DocumentReference? ref) => ref == null ? null : _initiativeNames[ref.id];

  Future<void> fetchEvents() async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _all = await _service.getEventsOnce();
      await _preloadInitiatives();
    } catch (e) {
      _errorMessage = e.toString();
      // ignore: avoid_print
      print("Error fetching events: $e");
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _preloadInitiatives() async {
    final ids = <String>{};
    for (final e in _all) {
      final ref = e.initiative;
      if (ref != null && !_initiativeNames.containsKey(ref.id)) ids.add(ref.id);
    }
    if (ids.isEmpty) return;
    try {
      final futures = ids.map((id) async {
        final doc = await FirebaseFirestore.instance.collection('initiatives').doc(id).get();
        final data = doc.data();
        if (data != null) _initiativeNames[id] = (data['title'] as String?) ?? 'Initiative';
      });
      await Future.wait(futures);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to preload initiative names: $e');
    }
    notifyListeners();
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setPublicOnly(bool v) {
    _publicOnly = v;
    notifyListeners();
  }

  Future<void> saveEvent(EventAnnouncement e) async {
    if (e.id.isEmpty) {
      await _service.addEvent(e);
    } else {
      await _service.updateEvent(e);
    }
    await fetchEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _service.deleteEvent(id);
    await fetchEvents();
  }
}
