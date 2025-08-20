import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/initiative_model.dart';
import '../../providers/initiative_provider.dart';
import '../../services/initiative_service.dart';

class InitiativeFormScreen extends StatefulWidget {
  final Initiative? initiative;
  const InitiativeFormScreen({super.key, this.initiative});

  @override
  _InitiativeFormScreenState createState() => _InitiativeFormScreenState();
}

class _InitiativeFormScreenState extends State<InitiativeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  String? _description;

  // Management fields
  final List<String> _categories = const ['infrastructure', 'education', 'health', 'community', 'relief', 'other'];
  final List<String> _statuses = const ['planned', 'active', 'on_hold', 'completed', 'cancelled'];
  String? _category;
  String _status = 'planned';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _durationMonths;

  // Public-app controls
  bool _publicVisible = true;
  bool _featured = false;
  String? _slug;
  // Media
  String? _coverImageUrl;
  List<String> _gallery = [];

  // Financial + milestones
  num? _goalAmount; // INR
  List<Map<String, dynamic>> _milestones = [];

  @override
  void initState() {
    super.initState();
    _title = widget.initiative?.title ?? '';
    _description = widget.initiative?.description;
    _category = widget.initiative?.category;
    _status = widget.initiative?.status ?? 'planned';
    _startDate = (widget.initiative?.startDate)?.toDate();
    _endDate = (widget.initiative?.endDate)?.toDate();
    _durationMonths = widget.initiative?.durationMonths;
    _publicVisible = widget.initiative?.publicVisible ?? true;
    _featured = widget.initiative?.featured ?? false;
    _slug = widget.initiative?.slug;
    _goalAmount = widget.initiative?.goalAmount;
    _milestones = List<Map<String, dynamic>>.from(widget.initiative?.milestones ?? []);
    _coverImageUrl = widget.initiative?.coverImageUrl;
    _gallery = List<String>.from(widget.initiative?.gallery ?? const <String>[]);
  }

  String _slugify(String input) {
    final s = input.trim().toLowerCase();
    final replaced = s.replaceAll(RegExp(r"[^a-z0-9]+"), '-');
    return replaced.replaceAll(RegExp(r"^-+|-+$"), '');
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addMilestone() {
    setState(() {
      _milestones.add({'title': '', 'percent': 0});
    });
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final initiativeProvider = context.read<InitiativeProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.initiative == null ? 'Add Initiative' : 'Edit Initiative')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _title = v ?? '',
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: _statuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                decoration: const InputDecoration(labelText: 'Status'),
                onChanged: (v) => setState(() => _status = v ?? 'planned'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Date'),
                        child: Text(_startDate == null ? 'Select date' : _startDate!.toLocal().toString().split(' ').first),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Date'),
                        child: Text(_endDate == null ? 'Select date' : _endDate!.toLocal().toString().split(' ').first),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _durationMonths?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Duration (months)'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _durationMonths = (v == null || v.isEmpty) ? null : int.tryParse(v),
              ),

              const Divider(height: 32),
              const Text('Financials', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _goalAmount?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Goal Amount (INR)', helperText: 'Enter total goal in INR'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _goalAmount = (v == null || v.isEmpty) ? null : num.tryParse(v),
              ),

              const SizedBox(height: 16),
              Row(
                children: const [
                  Text('Milestones', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ..._milestones.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: (m['title'] ?? '').toString(),
                          decoration: const InputDecoration(labelText: 'Title'),
                          onChanged: (v) => _milestones[i]['title'] = v,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: (m['percent']?.toString() ?? ''),
                                decoration: const InputDecoration(labelText: 'Percent (0-100)'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final p = num.tryParse(v) ?? 0;
                                  _milestones[i]['percent'] = p.clamp(0, 100);
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeMilestone(i),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addMilestone,
                  icon: const Icon(Icons.add),
                  label: const Text('Add milestone'),
                ),
              ),

              const Divider(height: 32),
              const Text('Media', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _coverImageUrl,
                decoration: const InputDecoration(
                  labelText: 'Banner URL (coverImageUrl)'
                ),
                onSaved: (v) => _coverImageUrl = (v == null || v.isEmpty) ? null : v.trim(),
              ),
              const SizedBox(height: 8),
              const Text('Gallery URLs'),
              const SizedBox(height: 6),
              ..._gallery.asMap().entries.map((e) => Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: e.value,
                      decoration: const InputDecoration(hintText: 'https://...'),
                      onChanged: (v) => _gallery[e.key] = v.trim(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(() => _gallery.removeAt(e.key)),
                  ),
                ],
              )),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _gallery.add('')),
                  icon: const Icon(Icons.add),
                  label: const Text('Add URL'),
                ),
              ),

              const Divider(height: 32),
              const Text('Public App Controls', style: TextStyle(fontWeight: FontWeight.w700)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible on Public App'),
                value: _publicVisible,
                onChanged: (v) => setState(() => _publicVisible = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Featured'),
                subtitle: const Text('Highlight on public app'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
              TextFormField(
                initialValue: _slug,
                decoration: const InputDecoration(labelText: 'Slug (public URL id, optional)'),
                onSaved: (v) => _slug = (v == null || v.isEmpty) ? null : v,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final computedSlug = _slug == null || _slug!.isEmpty ? _slugify(_title) : _slug!;
                    final uniqueSlug = await InitiativeService()
                        .ensureUniqueSlug(computedSlug, excludeId: widget.initiative?.id.isNotEmpty == true ? widget.initiative!.id : null);

                    // Normalize milestones
                    final ms = _milestones
                        .where((m) => (m['title'] ?? '').toString().trim().isNotEmpty)
                        .map((m) => {
                              'title': (m['title'] ?? '').toString().trim(),
                              'percent': ((m['percent'] is num) ? m['percent'] : num.tryParse('${m['percent']}') ?? 0).clamp(0, 100),
                            })
                        .toList();

                    // Normalize gallery (drop empties)
                    final gallery = _gallery.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                    final newInitiative = Initiative(
                      id: widget.initiative?.id ?? '',
                      title: _title,
                      description: _description,
                      category: _category,
                      status: _status,
                      startDate: _startDate != null ? Timestamp.fromDate(_startDate!) : null,
                      endDate: _endDate != null ? Timestamp.fromDate(_endDate!) : null,
                      durationMonths: _durationMonths,
                      publicVisible: _publicVisible,
                      featured: _featured,
                      slug: uniqueSlug,
                      goalAmount: _goalAmount,
                      milestones: ms,
                      coverImageUrl: _coverImageUrl,
                      gallery: gallery,
                    );
                    await initiativeProvider.saveInitiative(newInitiative);
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
