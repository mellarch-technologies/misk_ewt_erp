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
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateEvent(EventAnnouncement e) => _col.doc(e.id).update({
        ...e.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteEvent(String id) => _col.doc(id).delete();

  // Seed a few sample items (idempotent by title)
  Future<void> seedSampleEvents() async {
    final now = DateTime.now();
    final samples = [
      {
        'title': 'Monthly Community Meet',
        'description': 'Open forum and updates for members.',
        'type': 'event',
        'when': Timestamp.fromDate(now.add(const Duration(days: 7))),
        'publicVisible': true,
        'featured': true,
      },
      {
        'title': 'Quarterly Report Published',
        'description': 'Summary of initiatives and donations this quarter.',
        'type': 'announcement',
        'when': Timestamp.fromDate(now),
        'publicVisible': true,
        'featured': false,
      },
    ];

    for (final s in samples) {
      final q = await _col.where('title', isEqualTo: s['title']).limit(1).get();
      final data = {
        'title': s['title'],
        'description': s['description'],
        'type': s['type'],
        'eventDate': s['when'],
        'publicVisible': s['publicVisible'],
        'featured': s['featured'],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (q.docs.isEmpty) {
        await _col.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _col.doc(q.docs.first.id).update(data);
      }
    }
  }
}
