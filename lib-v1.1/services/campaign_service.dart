import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campaign_model.dart';

class CampaignService {
  final _col = FirebaseFirestore.instance.collection('campaigns');

  Future<List<Campaign>> getCampaignsOnce() async {
    final snap = await _col.orderBy('startDate').get();
    return snap.docs
        .map((doc) => Campaign.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Campaign>> streamCampaigns() => _col
      .orderBy('startDate')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Campaign.fromFirestore(doc.data(), doc.id))
          .toList());

  Future<void> addCampaign(Campaign c) => _col.add({
    ...c.toFirestore(),
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateCampaign(Campaign c) => _col.doc(c.id).update(c.toFirestore());

  Future<void> deleteCampaign(String id) => _col.doc(id).delete();

  Future<void> seedSampleCampaigns() async {
    final samples = [
      Campaign(
        id: '',
        name: 'Back to School',
        description: 'Annual campaign to support students with supplies.',
        startDate: Timestamp.now(),
        endDate: Timestamp.now(),
      ),
      Campaign(
        id: '',
        name: 'Community Health',
        description: 'Promoting health awareness and free checkups.',
        startDate: Timestamp.now(),
        endDate: Timestamp.now(),
      ),
      Campaign(
        id: '',
        name: 'Clean Water Awareness',
        description: 'Educating about clean water and hygiene.',
        startDate: Timestamp.now(),
        endDate: Timestamp.now(),
      ),
    ];
    for (final c in samples) {
      await addCampaign(c);
    }
  }
}
