import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/initiative_model.dart';

class InitiativeService {
  final _col = FirebaseFirestore.instance.collection('initiatives');

  Future<List<Initiative>> getInitiativesOnce() async {
    final snap = await _col.orderBy('startDate').get();
    return snap.docs
        .map((doc) => Initiative.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Initiative>> streamInitiatives() => _col
      .orderBy('startDate')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Initiative.fromFirestore(doc.data(), doc.id))
          .toList());

  Future<void> addInitiative(Initiative i) => _col.add({
    ...i.toFirestore(),
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateInitiative(Initiative i) => _col.doc(i.id).update(i.toFirestore());

  Future<void> deleteInitiative(String id) => _col.doc(id).delete();

  Future<void> seedSampleInitiatives() async {
    final samples = [
      Initiative(
        id: '',
        title: 'Education Drive',
        description: 'Providing school supplies to underprivileged children.',
        startDate: Timestamp.now(),
        endDate: Timestamp.now(),
      ),
      Initiative(
        id: '',
        title: 'Health Camp',
        description: 'Free medical checkups for the community.',
        startDate: Timestamp.now(),
        endDate: Timestamp.now(),
      ),
      Initiative(
        id: '',
        title: 'Clean Water Project',
        description: 'Installing water filters in rural areas.',
        startDate: Timestamp.now(),
        endDate: Timestamp.now(),
      ),
    ];
    for (final i in samples) {
      await addInitiative(i);
    }
  }

  Future<String> ensureUniqueSlug(String desired, {String? excludeId}) async {
    String base = desired;
    String candidate = base;
    int suffix = 1;
    while (true) {
      final q = await _col.where('slug', isEqualTo: candidate).limit(1).get();
      if (q.docs.isEmpty) return candidate;
      if (excludeId != null && q.docs.first.id == excludeId) return candidate;
      suffix += 1;
      candidate = '$base-$suffix';
    }
  }
}
