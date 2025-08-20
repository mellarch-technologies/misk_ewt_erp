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
    };
  }
}

