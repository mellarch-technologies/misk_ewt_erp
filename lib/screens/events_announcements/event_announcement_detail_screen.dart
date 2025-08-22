import 'package:flutter/material.dart';
import '../../models/event_announcement_model.dart';
import '../../models/initiative_model.dart';
import '../../theme/app_theme.dart';

class EventAnnouncementDetailScreen extends StatelessWidget {
  final EventAnnouncement event;
  const EventAnnouncementDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Event/Announcement Details')),
      body: Padding(
        padding: const EdgeInsets.all(MiskTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${event.title}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Description: ${event.description ?? "-"}'),
            SizedBox(height: 8),
            Text('Event Date: ${event.eventDate?.toDate().toString() ?? "-"}'),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}

class InitiativeDetailScreen extends StatelessWidget {
  final Initiative initiative;
  const InitiativeDetailScreen({super.key, required this.initiative});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Initiative Details')),
      body: Padding(
        padding: const EdgeInsets.all(MiskTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${initiative.title}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Description: ${initiative.description ?? "-"}'),
            SizedBox(height: 8),
            Text('Start Date: ${initiative.startDate?.toDate().toString() ?? "-"}'),
            SizedBox(height: 8),
            Text('End Date: ${initiative.endDate?.toDate().toString() ?? "-"}'),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}
