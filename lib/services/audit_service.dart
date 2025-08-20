// lib/services/audit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AuditService {
  final FirebaseFirestore _db;
  AuditService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<void> logAuthEvent({
    required String type, // 'login', 'logout', 'password_reset_request'
    String? email,
    String? uid,
    required bool success,
    String? errorCode,
    Map<String, dynamic>? extra,
  }) async {
    await _db.collection('auth_audit').add({
      'type': type,
      'email': email,
      'uid': uid,
      'success': success,
      if (errorCode != null) 'errorCode': errorCode,
      if (extra != null) ...extra,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

