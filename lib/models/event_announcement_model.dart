import 'package:cloud_firestore/cloud_firestore.dart';

class EventAnnouncement {
  final String id;
  final String title;
  final String? description;
  final Timestamp? eventDate;
  final String type; // 'event' | 'announcement'
  final bool publicVisible;
  final bool featured;
  final DocumentReference? initiative;
  final DocumentReference? createdBy;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  // New: posters for public carousel
  final List<String>? posterUrls;

  EventAnnouncement({
    required this.id,
    required this.title,
    this.description,
    this.eventDate,
    this.type = 'event',
    this.publicVisible = true,
    this.featured = false,
    this.initiative,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.posterUrls,
  });

  factory EventAnnouncement.fromFirestore(Map<String, dynamic> data, String documentId) {
    return EventAnnouncement(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'],
      eventDate: data['eventDate'],
      type: (data['type'] as String?) ?? 'event',
      publicVisible: (data['publicVisible'] as bool?) ?? true,
      featured: (data['featured'] as bool?) ?? false,
      initiative: data['initiative'],
      createdBy: data['createdBy'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      posterUrls: (data['posterUrls'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate,
      'type': type,
      'publicVisible': publicVisible,
      'featured': featured,
      'initiative': initiative,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'posterUrls': posterUrls,
    };
  }
}
