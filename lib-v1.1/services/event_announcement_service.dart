import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_announcement_model.dart';

class EventAnnouncementService {
  final _col = FirebaseFirestore.instance.collection('event_announcements');

  Future<List<EventAnnouncement>> getEventsOnce() async {
    final snap = await _col.orderBy('eventDate').get();
    return snap.docs
        .map((doc) => EventAnnouncement.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Stream<List<EventAnnouncement>> streamEvents() => _col
      .orderBy('eventDate')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => EventAnnouncement.fromFirestore(doc.data(), doc.id))
          .toList());

  Future<void> addEvent(EventAnnouncement e) => _col.add({
    ...e.toFirestore(),
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateEvent(EventAnnouncement e) => _col.doc(e.id).update(e.toFirestore());

  Future<void> deleteEvent(String id) => _col.doc(id).delete();
}

