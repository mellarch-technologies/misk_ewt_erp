import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/campaign_model.dart';
import '../../providers/campaign_provider.dart';
import '../../services/initiative_service.dart';
import '../../models/initiative_model.dart';
import '../../theme/app_theme.dart';

class CampaignFormScreen extends StatefulWidget {
  final Campaign? campaign;
  const CampaignFormScreen({super.key, this.campaign});

  @override
  _CampaignFormScreenState createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  String? _description;

  // New fields
  final List<String> _categories = const ['online', 'offline'];
  String? _category;
  bool _publicVisible = true;
  bool _featured = false;

  // Optional fields
  DateTime? _startDate;
  DateTime? _endDate;
  String? _proposedBy;
  num? _estimatedCost;
  // Media
  String? _featureBannerUrl;
  String? _posterUrl;

  // Initiative selection
  String? _initiativeId;

  @override
  void initState() {
    super.initState();
    _name = widget.campaign?.name ?? '';
    _description = widget.campaign?.description;
    _category = widget.campaign?.category;
    _publicVisible = widget.campaign?.publicVisible ?? true;
    _featured = widget.campaign?.featured ?? false;
    _startDate = widget.campaign?.startDate?.toDate();
    _endDate = widget.campaign?.endDate?.toDate();
    _proposedBy = widget.campaign?.proposedBy;
    _estimatedCost = widget.campaign?.estimatedCost;
    _featureBannerUrl = widget.campaign?.featureBannerUrl;
    _posterUrl = widget.campaign?.posterUrl;
    _initiativeId = widget.campaign?.initiative?.id;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CampaignProvider>(context);
    final initSvc = InitiativeService();
    return Scaffold(
      appBar: AppBar(title: Text(widget.campaign == null ? 'Add Campaign' : 'Edit Campaign')),
      body: Padding(
        padding: const EdgeInsets.all(MiskTheme.spacingMedium),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: MiskTheme.spacingSmall),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: MiskTheme.spacingSmall),
              FutureBuilder<List<Initiative>>(
                future: initSvc.getInitiativesOnce(),
                builder: (ctx, snap) {
                  final inits = snap.data ?? const <Initiative>[];
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: inits.any((i) => i.id == _initiativeId) ? _initiativeId : null,
                    items: inits.map((i) => DropdownMenuItem(value: i.id, child: Text(i.title))).toList(),
                    onChanged: (v) => setState(() => _initiativeId = v),
                    decoration: const InputDecoration(labelText: 'Initiative (link)'),
                  );
                },
              ),
              const SizedBox(height: MiskTheme.spacingSmall),
              Row(
                children: [
                  Expanded(
                    child: Text(_startDate == null
                        ? 'No start date'
                        : 'Start: ${_startDate!.toLocal().toString().split(' ').first}'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.event),
                    label: const Text('Pick Start'),
                  ),
                ],
              ),
              const SizedBox(height: MiskTheme.spacingXSmall),
              Row(
                children: [
                  Expanded(
                    child: Text(_endDate == null
                        ? 'No end date'
                        : 'End: ${_endDate!.toLocal().toString().split(' ').first}'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Pick End'),
                  ),
                ],
              ),
              const SizedBox(height: MiskTheme.spacingSmall),
              TextFormField(
                initialValue: _proposedBy,
                decoration: const InputDecoration(labelText: 'Proposed By'),
                onSaved: (v) => _proposedBy = v?.trim().isEmpty == true ? null : v?.trim(),
              ),
              const SizedBox(height: MiskTheme.spacingSmall),
              TextFormField(
                initialValue: _estimatedCost?.toString(),
                decoration: const InputDecoration(labelText: 'Estimated Cost (INR)'),
                keyboardType: TextInputType.number,
                onSaved: (v) {
                  final t = num.tryParse((v ?? '').replaceAll(',', ''));
                  _estimatedCost = t;
                },
              ),
              const Divider(height: MiskTheme.spacingLarge),
              const Text('Media', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: MiskTheme.spacingXSmall),
              TextFormField(
                initialValue: _featureBannerUrl,
                decoration: const InputDecoration(labelText: 'Feature Banner URL (wide image)'),
                onSaved: (v) => _featureBannerUrl = (v == null || v.isEmpty) ? null : v.trim(),
              ),
              const SizedBox(height: MiskTheme.spacingXSmall),
              TextFormField(
                initialValue: _posterUrl,
                decoration: const InputDecoration(labelText: 'Poster URL (single image)'),
                onSaved: (v) => _posterUrl = (v == null || v.isEmpty) ? null : v.trim(),
              ),
              const Divider(height: MiskTheme.spacingLarge),
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
              const SizedBox(height: MiskTheme.spacingMedium),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final initsCol = FirebaseFirestore.instance.collection('initiatives');
                    final newCampaign = Campaign(
                      id: widget.campaign?.id ?? '',
                      name: _name,
                      description: _description,
                      category: _category,
                      publicVisible: _publicVisible,
                      featured: _featured,
                      startDate: _startDate != null ? Timestamp.fromDate(_startDate!) : widget.campaign?.startDate,
                      endDate: _endDate != null ? Timestamp.fromDate(_endDate!) : widget.campaign?.endDate,
                      estimatedCost: _estimatedCost ?? widget.campaign?.estimatedCost,
                      proposedBy: _proposedBy ?? widget.campaign?.proposedBy,
                      initiative: _initiativeId != null ? initsCol.doc(_initiativeId) : widget.campaign?.initiative,
                      featureBannerUrl: _featureBannerUrl ?? widget.campaign?.featureBannerUrl,
                      posterUrl: _posterUrl ?? widget.campaign?.posterUrl,
                    );
                    await provider.saveCampaign(newCampaign);
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
