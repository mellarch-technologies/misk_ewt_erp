import 'package:flutter/material.dart';
import '../models/event_announcement_model.dart';
import '../services/event_announcement_service.dart';

class EventAnnouncementProvider extends ChangeNotifier {
  final EventAnnouncementService _service = EventAnnouncementService();
  List<EventAnnouncement> _all = [];
  String _filter = '';
  bool _busy = true;

  List<EventAnnouncement> get events => _filter.isEmpty
      ? _all
      : _all.where((e) => e.title.toLowerCase().contains(_filter)).toList();

  bool get isBusy => _busy;

  Future<void> fetchEvents() async {
    _busy = true;
    notifyListeners();
    try {
      _all = await _service.getEventsOnce();
    } catch (e) {
      print("Error fetching events: $e");
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
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
