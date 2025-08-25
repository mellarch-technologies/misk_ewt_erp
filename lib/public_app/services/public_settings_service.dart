// lib/public_app/services/public_settings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicSettingsService {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getPayments() async {
    try {
      final doc = await _db.collection('settings').doc('payments').get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return data;
    } catch (_) {
      return null;
    }
  }
}

