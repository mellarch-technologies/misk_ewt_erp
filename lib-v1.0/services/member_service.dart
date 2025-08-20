// lib/services/member_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class MemberService {
  final _col = FirebaseFirestore.instance.collection('members');

  Stream<List<MemberModel>> streamMembers() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => MemberModel.fromJson(d.data(), d.id)).toList());

  Future<void> addMember(MemberModel m) => _col.add(m.toJson());

  Future<void> updateMember(MemberModel m) => _col.doc(m.uid).update(m.toJson());

  Future<void> deleteMember(String uid) => _col.doc(uid).delete();
}
