import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/event_announcement_model.dart';
import '../../providers/event_announcement_provider.dart';
import '../../services/initiative_service.dart';
import '../../models/initiative_model.dart';
import '../../theme/app_theme.dart';
// Upload helpers
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../services/app_config.dart';
import '../../services/photo_repository.dart';
import '../../widgets/snackbar_helper.dart';

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
  DateTime? _eventDate;
  String _type = 'event';
  bool _publicVisible = true;
  bool _featured = false;
  String? _initiativeId;
  // Posters (URLs)
  List<String> _posterUrls = [];
  // Upload flag
  bool _uploadingPoster = false;

  @override
  void initState() {
    super.initState();
    _title = widget.event?.title ?? '';
    _description = widget.event?.description;
    _eventDate = widget.event?.eventDate?.toDate();
    _type = widget.event?.type ?? 'event';
    _publicVisible = widget.event?.publicVisible ?? true;
    _featured = widget.event?.featured ?? false;
    _initiativeId = widget.event?.initiative?.id;
    _posterUrls = List<String>.from(widget.event?.posterUrls ?? const <String>[]);
  }

  Future<void> _pickDateTime() async {
    final initialDate = _eventDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDate ?? DateTime.now()),
    );
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    setState(() => _eventDate = dt);
  }

  Future<String?> _pickAndUpload({required String directory, required String prefix}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return null;
      final raw = await picked.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        raw,
        minWidth: 1024,
        minHeight: 576,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      final repo = getPhotoRepository(AppConfig.photoStorage);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final url = await repo.upload(
        Uint8List.fromList(compressed),
        fileName: '${prefix}_$ts.jpg',
        mimeType: 'image/jpeg',
        directory: directory,
      );
      return url;
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Upload failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventAnnouncementProvider>(context);
    final initSvc = InitiativeService();
    final eventId = (widget.event?.id.isNotEmpty == true) ? widget.event!.id : null;
    final baseDir = eventId != null ? 'events/$eventId' : 'events/pending/${DateTime.now().millisecondsSinceEpoch}';
    return Scaffold(
      appBar: AppBar(title: Text(widget.event == null ? 'Add Event/Announcement' : 'Edit Event/Announcement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiskTheme.spacingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _title = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: const ['event', 'announcement']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'event'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _eventDate == null
                          ? 'No date/time set'
                          : 'When: ${_eventDate!.toLocal().toString().replaceFirst('.000', '')}',
                      maxLines: 2,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.event),
                    label: const Text('Pick Date/Time'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Initiative>>(
                future: initSvc.getInitiativesOnce(),
                builder: (ctx, snap) {
                  final inits = snap.data ?? const <Initiative>[];
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: inits.any((i) => i.id == _initiativeId) ? _initiativeId : null,
                    items: inits.map((i) => DropdownMenuItem(value: i.id, child: Text(i.title))).toList(),
                    onChanged: (v) => setState(() => _initiativeId = v),
                    decoration: const InputDecoration(labelText: 'Initiative (optional)'),
                  );
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Public visible'),
                value: _publicVisible,
                onChanged: (v) => setState(() => _publicVisible = v),
              ),
              SwitchListTile(
                title: const Text('Featured'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
              const Divider(height: 32),
              const Text('Posters', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_posterUrls.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _posterUrls.asMap().entries.map((e) {
                    final idx = e.key;
                    final url = e.value;
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(url, width: 120, height: 160, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 160,
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image),
                                  )),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.black87,
                          onPressed: () => setState(() => _posterUrls.removeAt(idx)),
                        ),
                      ],
                    );
                  }).toList(),
                )
              else
                const Text('No posters yet'),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploadingPoster
                        ? null
                        : () async {
                            setState(() => _uploadingPoster = true);
                            final url = await _pickAndUpload(directory: '$baseDir/posters', prefix: 'event_poster');
                            if (url != null) setState(() => _posterUrls.add(url));
                            if (mounted) setState(() => _uploadingPoster = false);
                          },
                    icon: _uploadingPoster
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file),
                    label: const Text('Upload poster'),
                  ),
                  const SizedBox(width: 8),
                  if (_posterUrls.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => setState(() => _posterUrls.clear()),
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final initsCol = FirebaseFirestore.instance.collection('initiatives');
                    final posters = _posterUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final newEvent = EventAnnouncement(
                      id: widget.event?.id ?? '',
                      title: _title,
                      description: _description,
                      eventDate: _eventDate != null ? Timestamp.fromDate(_eventDate!) : widget.event?.eventDate,
                      type: _type,
                      publicVisible: _publicVisible,
                      featured: _featured,
                      initiative: _initiativeId != null ? initsCol.doc(_initiativeId) : widget.event?.initiative,
                      posterUrls: posters,
                    );
                    await provider.saveEvent(newEvent);
                    if (mounted) Navigator.pop(context, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
