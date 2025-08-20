import 'package:cloud_firestore/cloud_firestore.dart';
import './rollup_service.dart' as roll;
import '../models/donation_model.dart';

class DonationService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('donations');

  Future<List<Donation>> getDonationsOnce({DocumentReference? initiative, DocumentReference? campaignRef}) async {
    Query<Map<String, dynamic>> q = _col;
    if (initiative != null) {
      q = q.where('initiative', isEqualTo: initiative);
    }
    if (campaignRef != null) {
      q = q.where('campaign', isEqualTo: campaignRef);
    }
    final snap = await q.get();
    final items = snap.docs
        .map((d) => Donation.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
    items.sort((a, b) {
      final ta = (a.receivedAt ?? a.createdAt)?.toDate();
      final tb = (b.receivedAt ?? b.createdAt)?.toDate();
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return items;
  }

  Stream<List<Donation>> streamDonations({DocumentReference? initiative, DocumentReference? campaignRef}) {
    Query<Map<String, dynamic>> q = _col;
    if (initiative != null) {
      q = q.where('initiative', isEqualTo: initiative);
    }
    if (campaignRef != null) {
      q = q.where('campaign', isEqualTo: campaignRef);
    }
    return q.snapshots().map((s) {
      final items = s.docs
          .map((d) => Donation.fromFirestore(d.data() as Map<String, dynamic>, d.id))
          .toList();
      items.sort((a, b) {
        final ta = (a.receivedAt ?? a.createdAt)?.toDate();
        final tb = (b.receivedAt ?? b.createdAt)?.toDate();
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
      return items;
    });
  }

  Future<String> addDonation(Donation d) async {
    final data = {
      ...d.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final res = await _col.add(data);
    await roll.RollupService().recomputeInitiativeFinancial(d.initiative);
    return res.id;
  }

  Future<void> updateDonation(Donation d) async {
    await _col.doc(d.id).update({
      ...d.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await roll.RollupService().recomputeInitiativeFinancial(d.initiative);
  }

  Future<void> deleteDonation(Donation d) async {
    await _col.doc(d.id).delete();
    await roll.RollupService().recomputeInitiativeFinancial(d.initiative);
  }

  // New: partial update for quick reconciliation/status changes
  Future<void> quickUpdate(
    String id,
    DocumentReference initiativeRef, {
    bool? bankReconciled,
    String? bankRef,
    String? status,
  }) async {
    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (bankReconciled != null) {
      update['bankReconciled'] = bankReconciled;
      update['reconciledAt'] = bankReconciled ? FieldValue.serverTimestamp() : null;
    }
    if (bankRef != null) update['bankRef'] = bankRef;
    if (status != null) update['status'] = status;

    await _col.doc(id).update(update);
    await roll.RollupService().recomputeInitiativeFinancial(initiativeRef);
  }
}
