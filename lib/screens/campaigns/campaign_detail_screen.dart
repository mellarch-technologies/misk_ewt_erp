import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/campaign_model.dart';
import '../donations/donations_list_screen.dart';

class CampaignDetailScreen extends StatelessWidget {
  final Campaign campaign;
  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Campaign Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${campaign.name}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Description: ${campaign.description ?? "-"}'),
            SizedBox(height: 8),
            Text('Start Date: ${campaign.startDate?.toDate().toString() ?? "-"}'),
            SizedBox(height: 8),
            Text('End Date: ${campaign.endDate?.toDate().toString() ?? "-"}'),
            // Add more fields as needed
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final initRef = campaign.initiative;
                    if (initRef == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link this campaign to an initiative to view donations.')),
                      );
                      return;
                    }
                    final campRef = FirebaseFirestore.instance.collection('campaigns').doc(campaign.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DonationsListScreen(initiativeRef: initRef, campaignRef: campRef),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View Donations'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
