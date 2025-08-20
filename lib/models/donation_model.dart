import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final num amount;
  final String currency; // 'INR'
  final String status; // pending, confirmed, failed, refunded
  final bool bankReconciled; // true if reflected in bank
  final String? bankRef; // bank statement ref/UTR/check no
  final Timestamp? reconciledAt;
  final DocumentReference initiative; // required
  final DocumentReference? campaign; // optional attribution
  // Donor minimal PII
  final String donorName;
  final String donorPhone;
  final String donorEmail;
  final String? donorPan; // required at >= 10000 (validated in UI/service)
  final String? donorAddress;
  // Payment/meta
  final String method; // UPI, Card, NetBanking, Cash, Cheque, Other
  final String? txnId;
  final String source; // public_app, erp, import
  final String? receiptNo;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? receivedAt;

  Donation({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.bankReconciled,
    this.bankRef,
    this.reconciledAt,
    required this.initiative,
    this.campaign,
    required this.donorName,
    required this.donorPhone,
    required this.donorEmail,
    this.donorPan,
    this.donorAddress,
    required this.method,
    this.txnId,
    required this.source,
    this.receiptNo,
    this.createdAt,
    this.updatedAt,
    this.receivedAt,
  });

  factory Donation.fromFirestore(Map<String, dynamic> data, String id) {
    return Donation(
      id: id,
      amount: data['amount'] ?? 0,
      currency: data['currency'] ?? 'INR',
      status: data['status'] ?? 'pending',
      bankReconciled: (data['bankReconciled'] as bool?) ?? false,
      bankRef: data['bankRef'],
      reconciledAt: data['reconciledAt'],
      initiative: data['initiative'],
      campaign: data['campaign'],
      donorName: data['donor']?['name'] ?? '',
      donorPhone: data['donor']?['phone'] ?? '',
      donorEmail: data['donor']?['email'] ?? '',
      donorPan: data['donor']?['pan'],
      donorAddress: data['donor']?['address'],
      method: data['method'] ?? 'Other',
      txnId: data['txnId'],
      source: data['source'] ?? 'erp',
      receiptNo: data['receiptNo'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      receivedAt: data['receivedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'currency': currency,
      'status': status,
      'bankReconciled': bankReconciled,
      'bankRef': bankRef,
      'reconciledAt': reconciledAt,
      'initiative': initiative,
      'campaign': campaign,
      'donor': {
        'name': donorName,
        'phone': donorPhone,
        'email': donorEmail,
        'pan': donorPan,
        'address': donorAddress,
      },
      'method': method,
      'txnId': txnId,
      'source': source,
      'receiptNo': receiptNo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'receivedAt': receivedAt,
    };
  }
}

