import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  final String id;
  final String name;
  final String? description;
  final DocumentReference? manager;
  final Timestamp? startDate;
  final Timestamp? endDate;
  // New: explicit parent initiative (preferred going forward)
  final DocumentReference? initiative;
  // Back-compat: keep list of initiatives if previously used
  final List<DocumentReference>? initiatives;
  final String? category; // e.g., 'online' | 'offline'
  // New (Batch 1): campaign classification and fundraising fields
  final String? type; // e.g., 'fundraising','outreach','ops','event','comms'
  final num? goalAmount; // goal for this campaign (esp. fundraising)
  final num? raisedAmount; // display-only; do not use in roll-up totals
  final int? donationsCount; // optional counter for attribution
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final bool publicVisible; // ERP control: show on public app
  final bool featured; // highlight on public app
  final String status; // planned, active, on_hold, completed, cancelled
  final String? priority; // low, medium, high
  final num? estimatedCost;
  final num? actualCost;
  final String? implementationPlan;
  final String? proposedBy;
  // New: media assets for public showcase
  final String? featureBannerUrl; // wide banner for campaign detail/list hero
  final String? posterUrl; // single poster image for campaign

  Campaign({
    required this.id,
    required this.name,
    this.description,
    this.manager,
    this.startDate,
    this.endDate,
    this.initiative,
    this.initiatives,
    this.category,
    this.type,
    this.goalAmount,
    this.raisedAmount,
    this.donationsCount,
    this.createdAt,
    this.updatedAt,
    this.publicVisible = true,
    this.featured = false,
    this.status = 'planned',
    this.priority,
    this.estimatedCost,
    this.actualCost,
    this.implementationPlan,
    this.proposedBy,
    this.featureBannerUrl,
    this.posterUrl,
  });

  factory Campaign.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Campaign(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'],
      manager: data['manager'],
      startDate: data['startDate'],
      endDate: data['endDate'],
      initiative: data['initiative'],
      initiatives: (data['initiatives'] as List?)?.cast<DocumentReference>(),
      category: data['category'],
      type: data['type'],
      goalAmount: data['goalAmount'],
      raisedAmount: data['raisedAmount'],
      donationsCount: (data['donationsCount'] is int) ? data['donationsCount'] as int : (data['donationsCount'] is num ? (data['donationsCount'] as num).toInt() : null),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      publicVisible: (data['publicVisible'] as bool?) ?? true,
      featured: (data['featured'] as bool?) ?? false,
      status: (data['status'] as String?) ?? 'planned',
      priority: data['priority'],
      estimatedCost: data['estimatedCost'],
      actualCost: data['actualCost'],
      implementationPlan: data['implementationPlan'],
      proposedBy: data['proposedBy'],
      featureBannerUrl: data['featureBannerUrl'],
      posterUrl: data['posterUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'manager': manager,
      'startDate': startDate,
      'endDate': endDate,
      'initiative': initiative,
      'initiatives': initiatives,
      'category': category,
      'type': type,
      'goalAmount': goalAmount,
      'raisedAmount': raisedAmount,
      'donationsCount': donationsCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'publicVisible': publicVisible,
      'featured': featured,
      'status': status,
      'priority': priority,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'implementationPlan': implementationPlan,
      'proposedBy': proposedBy,
      'featureBannerUrl': featureBannerUrl,
      'posterUrl': posterUrl,
    };
  }
}
