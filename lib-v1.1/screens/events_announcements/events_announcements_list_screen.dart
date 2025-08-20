import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_announcement_provider.dart';

class EventsAnnouncementsListScreen extends StatelessWidget {
  const EventsAnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventAnnouncementProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Events & Announcements')),
      body: RefreshIndicator(
        onRefresh: provider.fetchEvents,
        child: provider.isBusy
            ? Center(child: CircularProgressIndicator())
            : provider.events.isEmpty
                ? Center(child: Text('No events or announcements found.'))
                : ListView.builder(
                    itemCount: provider.events.length,
                    itemBuilder: (context, i) {
                      final event = provider.events[i];
                      return ListTile(
                        title: Text(event.title),
                        subtitle: Text(event.description ?? ''),
                        onTap: () {
                          // Navigate to detail screen
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to form screen
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
