import 'package:cloud_firestore/cloud_firestore.dart';

class RollupService {
  final _donations = FirebaseFirestore.instance.collection('donations');

  Future<void> recomputeInitiativeFinancial(DocumentReference initiativeRef) async {
    // Fetch confirmed donations for the initiative
    final q = await _donations
        .where('initiative', isEqualTo: initiativeRef)
        .where('status', isEqualTo: 'confirmed')
        .get();

    num confirmedSum = 0;
    num reconciledSum = 0;
    for (final d in q.docs) {
      final data = d.data();
      final amt = (data['amount'] as num?) ?? 0;
      confirmedSum += amt;
      final bankReconciled = (data['bankReconciled'] as bool?) ?? false;
      if (bankReconciled) reconciledSum += amt;
    }

    // Read manualAdjustmentAmount (default 0)
    final initSnap = await initiativeRef.get();
    final initData = initSnap.data() as Map<String, dynamic>?;
    final manualAdj = (initData?['manualAdjustmentAmount'] as num?) ?? 0;

    final computedRaised = confirmedSum + manualAdj;
    final computedReconciled = reconciledSum + manualAdj;

    await initiativeRef.update({
      'computedRaisedAmount': computedRaised,
      'reconciledRaisedAmount': computedReconciled,
      'lastComputedAt': FieldValue.serverTimestamp(),
    });
  }
}
