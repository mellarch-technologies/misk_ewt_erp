import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';

class CampaignsListScreen extends StatelessWidget {
  const CampaignsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CampaignProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Campaigns'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.fetchCampaigns,
        child: provider.isBusy
            ? Center(child: CircularProgressIndicator())
            : provider.campaigns.isEmpty
                ? Center(child: Text('No campaigns found.'))
                : ListView.builder(
                    itemCount: provider.campaigns.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(provider.campaigns[i].name),
                      subtitle: Text(provider.campaigns[i].description ?? ''),
                      onTap: () {
                        // Navigate to campaign details
                      },
                    ),
                  ),
      ),
    );
  }
}
