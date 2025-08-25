// lib/public_app/services/public_donation_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicDonationService {
  final _col = FirebaseFirestore.instance.collection('public_pending_donations');

  // Accepts a payload from UI; writes a sanitized, minimal pending donation.
  // Required: amount (>0), donorName, donorEmail, method in ['bank','upi','razorpay']
  // Optional: donorPhone, pan, address, bankRef/utr, campaignId/initiativeId (not stored here yet)
  Future<String> submitPendingDonation(Map<String, dynamic> payload) async {
    // Basic validation
    final amount = (payload['amount'] as num?);
    if (amount == null || amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    final donorName = (payload['donorName'] as String?)?.trim() ?? '';
    final donorEmail = (payload['donorEmail'] as String?)?.trim() ?? '';
    if (donorName.isEmpty) throw ArgumentError('Donor name is required');
    if (donorEmail.isEmpty || !donorEmail.contains('@')) {
      throw ArgumentError('Valid email is required');
    }
    final method = ((payload['method'] as String?) ?? '').toLowerCase();
    const allowedMethods = {'bank', 'upi', 'razorpay'};
    if (!allowedMethods.contains(method)) {
      throw ArgumentError('Unsupported method');
    }

    // PAN/Address gate for >= 10000 (UI already enforces; double-check here)
    final needsPan = amount >= 10000;
    final pan = (payload['pan'] as String?)?.trim();
    final address = (payload['address'] as String?)?.trim();
    if (needsPan && (pan == null || pan.isEmpty || address == null || address.isEmpty)) {
      throw ArgumentError('PAN and address are required for 10,000 and above');
    }

    // Normalize identifiers
    final bankRef = (payload['bankRef'] as String?)?.trim();
    final utr = (payload['utr'] as String?)?.trim();

    final doc = <String, dynamic>{
      'amount': amount,
      'currency': 'INR',
      'status': 'pending',
      'method': method,
      'source': 'public_app',
      'donor': {
        'name': donorName,
        'email': donorEmail,
        'phone': (payload['donorPhone'] as String?)?.trim(),
        'pan': pan,
        'address': address,
      },
      // Store either bankRef or utr if provided
      if (bankRef != null && bankRef.isNotEmpty) 'bankRef': bankRef,
      if (utr != null && utr.isNotEmpty) 'utr': utr,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final res = await _col.add(doc);
    return res.id;
  }
}
