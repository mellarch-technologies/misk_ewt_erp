import 'package:cloud_firestore/cloud_firestore.dart';

class Initiative {
  final String id;
  final String title;
  final String? description;
  final DocumentReference? owner;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final List<DocumentReference>? participants;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Initiative({
    required this.id,
    required this.title,
    this.description,
    this.owner,
    this.startDate,
    this.endDate,
    this.participants,
    this.createdAt,
    this.updatedAt,
  });

  factory Initiative.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Initiative(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'],
      owner: data['owner'],
      startDate: data['startDate'],
      endDate: data['endDate'],
      participants: (data['participants'] as List?)?.cast<DocumentReference>(),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'owner': owner,
      'startDate': startDate,
      'endDate': endDate,
      'participants': participants,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

