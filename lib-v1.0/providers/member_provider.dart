// lib/providers/member_provider.dart
import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../services/member_service.dart';

class MemberProvider extends ChangeNotifier {
  final _service = MemberService();
  List<MemberModel> _all = [];
  bool _busy = false;

  List<MemberModel> get members => _all;
  bool get isBusy => _busy;

  Future<void> fetchMembers() async {
    _busy = true;
    notifyListeners();
    _service.streamMembers().listen((data) {
      _all = data;
      _busy = false;
      notifyListeners();
    });
  }

  Future<void> save(MemberModel m) async {
    _busy = true; notifyListeners();
    if (m.uid.isEmpty) {
      await _service.addMember(m);
    } else {
      await _service.updateMember(m);
    }
    _busy = false; notifyListeners();
  }

  Future<void> remove(String uid) async {
    await _service.deleteMember(uid);
  }
}
