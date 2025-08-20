import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  final String id;
  final String name;
  final String? description;
  final DocumentReference? manager;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final List<DocumentReference>? initiatives;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Campaign({
    required this.id,
    required this.name,
    this.description,
    this.manager,
    this.startDate,
    this.endDate,
    this.initiatives,
    this.createdAt,
    this.updatedAt,
  });

  factory Campaign.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Campaign(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'],
      manager: data['manager'],
      startDate: data['startDate'],
      endDate: data['endDate'],
      initiatives: (data['initiatives'] as List?)?.cast<DocumentReference>(),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'manager': manager,
      'startDate': startDate,
      'endDate': endDate,
      'initiatives': initiatives,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

