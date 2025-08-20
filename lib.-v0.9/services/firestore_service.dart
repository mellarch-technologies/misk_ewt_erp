import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _path = 'members';

  Stream<List<Member>> getMembers() =>
      _db.collection(_path)
          .orderBy('CreatedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => Member.fromFirestore(doc)).toList());

  Future<void> addMember(Member m) {
    final data = m.toMap();
    data['CreatedAt'] = FieldValue.serverTimestamp();
    return _db.collection(_path).add(data);
  }

  Future<void> updateMember(Member m) =>
      _db.collection(_path).doc(m.id).update(m.toMap());

  Future<void> deleteMember(String id) =>
      _db.collection(_path).doc(id).delete();
}
