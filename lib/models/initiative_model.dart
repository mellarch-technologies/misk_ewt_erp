import 'package:cloud_firestore/cloud_firestore.dart';

class Initiative {
  final String id;
  final String title;
  final String? description;
  final DocumentReference? owner;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final List<DocumentReference>? participants;
  // Public-facing fields for the upcoming public app
  final bool publicVisible; // whether to showcase publicly
  final String? slug; // for clean public URLs
  final bool featured; // highlight on public app
  final String? coverImageUrl; // hero image (URL only; no Firebase Storage used)
  final List<String>? gallery; // additional image URLs
  final List<String>? tags; // categories/filters
  final String? location; // city/area
  final num? goalAmount; // fundraising goal
  // Kept for back-compat (may represent manual input)
  final num? raisedAmount; // legacy/manual value
  final List<Map<String, dynamic>>? milestones; // progress checkpoints
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? category; // e.g., infrastructure/education/health/community/other
  final String status; // planned, active, on_hold, completed, cancelled
  final int? durationMonths; // optional explicit duration; can be derived from dates
  final DocumentReference? teamHead; // explicit team lead (user doc)
  final List<DocumentReference>? teamMembers; // explicit team members (user docs)

  // New (Batch 1): computed roll-ups and execution
  final num? computedRaisedAmount; // sum(confirmed donations) + manualAdjustmentAmount
  final num? reconciledRaisedAmount; // sum(confirmed & bankReconciled) + manualAdjustmentAmount
  final num? manualAdjustmentAmount; // manual adds/corrections
  final num? computedExecutionPercent; // weighted/equal milestone completion (0-100)
  final Timestamp? lastComputedAt; // when roll-ups were last computed

  Initiative({
    required this.id,
    required this.title,
    this.description,
    this.owner,
    this.startDate,
    this.endDate,
    this.participants,
    this.publicVisible = true,
    this.slug,
    this.featured = false,
    this.coverImageUrl,
    this.gallery,
    this.tags,
    this.location,
    this.goalAmount,
    this.raisedAmount,
    this.milestones,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.status = 'planned',
    this.durationMonths,
    this.teamHead,
    this.teamMembers,
    this.computedRaisedAmount,
    this.reconciledRaisedAmount,
    this.manualAdjustmentAmount,
    this.computedExecutionPercent,
    this.lastComputedAt,
  });

  factory Initiative.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Initiative(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'],
      owner: data['owner'],
      startDate: data['startDate'],
      endDate: data['endDate'],
      participants: (data['participants'] as List?)?.cast<DocumentReference>(),
      publicVisible: (data['publicVisible'] as bool?) ?? true,
      slug: data['slug'],
      featured: (data['featured'] as bool?) ?? false,
      coverImageUrl: data['coverImageUrl'],
      gallery: (data['gallery'] as List?)?.map((e) => e.toString()).toList(),
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList(),
      location: data['location'],
      goalAmount: data['goalAmount'],
      raisedAmount: data['raisedAmount'],
      milestones: (data['milestones'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      category: data['category'],
      status: (data['status'] as String?) ?? 'planned',
      durationMonths: (data['durationMonths'] is int) ? data['durationMonths'] as int : null,
      teamHead: data['teamHead'],
      teamMembers: (data['teamMembers'] as List?)?.cast<DocumentReference>(),
      computedRaisedAmount: data['computedRaisedAmount'],
      reconciledRaisedAmount: data['reconciledRaisedAmount'],
      manualAdjustmentAmount: data['manualAdjustmentAmount'],
      computedExecutionPercent: data['computedExecutionPercent'],
      lastComputedAt: data['lastComputedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'title': title,
      'publicVisible': publicVisible,
      'featured': featured,
      'status': status,
    };
    if (description != null) map['description'] = description;
    if (owner != null) map['owner'] = owner;
    if (startDate != null) map['startDate'] = startDate;
    if (endDate != null) map['endDate'] = endDate;
    if (participants != null) map['participants'] = participants;
    if (slug != null) map['slug'] = slug;
    if (coverImageUrl != null) map['coverImageUrl'] = coverImageUrl;
    if (gallery != null) map['gallery'] = gallery;
    if (tags != null) map['tags'] = tags;
    if (location != null) map['location'] = location;
    if (goalAmount != null) map['goalAmount'] = goalAmount;
    if (raisedAmount != null) map['raisedAmount'] = raisedAmount;
    if (milestones != null) map['milestones'] = milestones;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    if (category != null) map['category'] = category;
    if (durationMonths != null) map['durationMonths'] = durationMonths;
    if (teamHead != null) map['teamHead'] = teamHead;
    if (teamMembers != null) map['teamMembers'] = teamMembers;

    // Computed fields: only include if explicitly set (avoid wiping with null on edit)
    if (computedRaisedAmount != null) map['computedRaisedAmount'] = computedRaisedAmount;
    if (reconciledRaisedAmount != null) map['reconciledRaisedAmount'] = reconciledRaisedAmount;
    if (manualAdjustmentAmount != null) map['manualAdjustmentAmount'] = manualAdjustmentAmount;
    if (computedExecutionPercent != null) map['computedExecutionPercent'] = computedExecutionPercent;
    if (lastComputedAt != null) map['lastComputedAt'] = lastComputedAt;

    return map;
  }
}
