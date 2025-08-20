import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DocumentReference? assignedTo;
  final DocumentReference? workflow;
  final String status;
  final Timestamp? dueDate;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final DocumentReference? campaign; // optional parent campaign
  final DocumentReference? initiative; // optional direct initiative link (for independent tasks)
  final bool publicVisible; // show task on public app
  final bool featured; // highlight task on public app

  Task({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.workflow,
    this.status = 'pending',
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.campaign,
    this.initiative,
    this.publicVisible = true,
    this.featured = false,
  });

  factory Task.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'],
      assignedTo: data['assignedTo'],
      workflow: data['workflow'],
      status: data['status'] ?? 'pending',
      dueDate: data['dueDate'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      campaign: data['campaign'],
      initiative: data['initiative'],
      publicVisible: (data['publicVisible'] as bool?) ?? true,
      featured: (data['featured'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'workflow': workflow,
      'status': status,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'campaign': campaign,
      'initiative': initiative,
      'publicVisible': publicVisible,
      'featured': featured,
    };
  }
}
