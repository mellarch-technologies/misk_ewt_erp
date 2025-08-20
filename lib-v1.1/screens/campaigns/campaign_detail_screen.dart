import 'package:flutter/material.dart';
import '../../models/campaign_model.dart';

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
          ],
        ),
      ),
    );
  }
}

