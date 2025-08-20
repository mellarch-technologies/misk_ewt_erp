import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final _col = FirebaseFirestore.instance.collection('tasks');

  Future<List<Task>> getTasksOnce() async {
    final snap = await _col.orderBy('dueDate').get();
    return snap.docs
        .map((doc) => Task.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Task>> streamTasks() => _col
      .orderBy('dueDate')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Task.fromFirestore(doc.data(), doc.id))
          .toList());

  Future<void> addTask(Task t) => _col.add({
    ...t.toFirestore(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateTask(Task t) => _col.doc(t.id).update({
    ...t.toFirestore(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteTask(String id) => _col.doc(id).delete();

  Future<void> seedSampleTasks() async {
    final samples = [
      Task(
        id: '',
        title: 'Prepare School Kits',
        description: 'Assemble and distribute school kits for students.',
        status: 'pending',
        dueDate: Timestamp.now(),
      ),
      Task(
        id: '',
        title: 'Health Camp Setup',
        description: 'Organize logistics for health camp.',
        status: 'pending',
        dueDate: Timestamp.now(),
      ),
      Task(
        id: '',
        title: 'Water Filter Installation',
        description: 'Install filters in designated locations.',
        status: 'pending',
        dueDate: Timestamp.now(),
      ),
    ];
    for (final t in samples) {
      await addTask(t);
    }
  }
}
