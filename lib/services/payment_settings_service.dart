// lib/services/payment_settings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSettingsService {
  final DocumentReference<Map<String, dynamic>> _doc =
      FirebaseFirestore.instance.collection('settings').doc('payments');

  Future<Map<String, dynamic>> load() async {
    final snap = await _doc.get();
    if (!snap.exists) return {};
    return snap.data() ?? {};
  }

  Future<void> save(Map<String, dynamic> data) async {
    // Merge to preserve unknown future fields
    await _doc.set(data, SetOptions(merge: true));
  }
}

