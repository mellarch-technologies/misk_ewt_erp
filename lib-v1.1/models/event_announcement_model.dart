import 'package:cloud_firestore/cloud_firestore.dart';

class EventAnnouncement {
  final String id;
  final String title;
  final String? description;
  final Timestamp? eventDate;
  final DocumentReference? createdBy;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  EventAnnouncement({
    required this.id,
    required this.title,
    this.description,
    this.eventDate,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory EventAnnouncement.fromFirestore(Map<String, dynamic> data, String documentId) {
    return EventAnnouncement(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'],
      eventDate: data['eventDate'],
      createdBy: data['createdBy'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

