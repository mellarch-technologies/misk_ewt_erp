import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_announcement_model.dart';
import '../../providers/event_announcement_provider.dart';

class EventAnnouncementFormScreen extends StatefulWidget {
  final EventAnnouncement? event;
  const EventAnnouncementFormScreen({super.key, this.event});

  @override
  _EventAnnouncementFormScreenState createState() => _EventAnnouncementFormScreenState();
}

class _EventAnnouncementFormScreenState extends State<EventAnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  String? _description;

  @override
  void initState() {
    super.initState();
    _title = widget.event?.title ?? '';
    _description = widget.event?.description;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventAnnouncementProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.event == null ? 'Add Event/Announcement' : 'Edit Event/Announcement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _title = v ?? '',
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (v) => _description = v,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final newEvent = EventAnnouncement(
                      id: widget.event?.id ?? '',
                      title: _title,
                      description: _description,
                    );
                    await provider.saveEvent(newEvent);
                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
