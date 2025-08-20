// services/firebase_service.dart
// This class handles all communication with the Firestore database.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/phase_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<Project> _projectsRef;

  FirebaseService() {
    _projectsRef = _db.collection('projects').withConverter<Project>(
      fromFirestore: (snapshots, _) => Project.fromFirestore(snapshots),
      toFirestore: (project, _) => project.toFirestore(),
    );
  }

  // Stream to get real-time updates for all projects
  Stream<List<Project>> getProjectsStream() {
    return _projectsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Function to add a new project to the 'projects' collection
  Future<void> addProject(Project project) {
    return _projectsRef.add(project);
  }

  // Function to get a stream of phases for a specific project
  Stream<List<Phase>> getPhasesStream(String projectId) {
    return _projectsRef
        .doc(projectId)
        .collection('phases')
        .withConverter<Phase>(
      fromFirestore: (snapshots, _) => Phase.fromFirestore(snapshots),
      toFirestore: (phase, _) => phase.toFirestore(),
    )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Function to add a new phase to a project's subcollection
  Future<void> addPhase(String projectId, Phase phase) {
    return _projectsRef
        .doc(projectId)
        .collection('phases')
        .withConverter<Phase>(
      fromFirestore: (snapshots, _) => Phase.fromFirestore(snapshots),
      toFirestore: (phase, _) => phase.toFirestore(),
    )
        .add(phase);
  }
}