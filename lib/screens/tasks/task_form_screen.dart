import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../services/initiative_service.dart';
import '../../models/initiative_model.dart';
import '../../services/campaign_service.dart';
import '../../models/campaign_model.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  String? _description;
  String _status = 'pending';
  DateTime? _dueDate;
  bool _publicVisible = true;
  bool _featured = false;

  // New: selections by id for dropdowns
  String? _assignedUserId;
  String? _initiativeId;
  String? _campaignId;

  @override
  void initState() {
    super.initState();
    _title = widget.task?.title ?? '';
    _description = widget.task?.description;
    _status = widget.task?.status ?? 'pending';
    _dueDate = widget.task?.dueDate?.toDate();
    _publicVisible = widget.task?.publicVisible ?? true;
    _featured = widget.task?.featured ?? false;
    _assignedUserId = widget.task?.assignedTo?.id;
    _initiativeId = widget.task?.initiative?.id;
    _campaignId = widget.task?.campaign?.id;
  }

  Future<void> _pickDueDate() async {
    final initial = _dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final userSvc = UserService();
    final initSvc = InitiativeService();
    final campSvc = CampaignService();

    return Scaffold(
      appBar: AppBar(title: Text(widget.task == null ? 'Add Task' : 'Edit Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                initialValue: _status,
                items: const ['pending', 'in_progress', 'completed']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'pending'),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(_dueDate == null
                        ? 'No due date'
                        : 'Due: ${_dueDate!.toLocal().toString().split(' ').first}'),
                  ),
                  TextButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.event),
                    label: const Text('Pick Due Date'),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text('Links & Assignment', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              FutureBuilder<List<UserModel>>(
                future: userSvc.getUsersOnce(),
                builder: (ctx, snap) {
                  final users = snap.data ?? const <UserModel>[];
                  return DropdownButtonFormField<String>(
                    initialValue: users.any((u) => u.uid == _assignedUserId) ? _assignedUserId : null,
                    items: users
                        .map((u) => DropdownMenuItem(value: u.uid, child: Text(u.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _assignedUserId = v),
                    decoration: const InputDecoration(labelText: 'Assigned To'),
                  );
                },
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Initiative>>(
                future: initSvc.getInitiativesOnce(),
                builder: (ctx, snap) {
                  final inits = snap.data ?? const <Initiative>[];
                  return DropdownButtonFormField<String>(
                    initialValue: inits.any((i) => i.id == _initiativeId) ? _initiativeId : null,
                    items: inits
                        .map((i) => DropdownMenuItem(value: i.id, child: Text(i.title)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _initiativeId = v;
                      // Clear campaign if initiative changed
                      _campaignId = null;
                    }),
                    decoration: const InputDecoration(labelText: 'Initiative (optional)'),
                  );
                },
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Campaign>>(
                future: campSvc.getCampaignsOnce(),
                builder: (ctx, snap) {
                  final all = snap.data ?? const <Campaign>[];
                  final camps = _initiativeId == null
                      ? all
                      : all.where((c) => c.initiative?.id == _initiativeId).toList();
                  return DropdownButtonFormField<String>(
                    initialValue: camps.any((c) => c.id == _campaignId) ? _campaignId : null,
                    items: camps
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _campaignId = v),
                    decoration: const InputDecoration(labelText: 'Campaign (optional)'),
                  );
                },
              ),
              const Divider(height: 32),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final usersCol = FirebaseFirestore.instance.collection('users');
                    final initsCol = FirebaseFirestore.instance.collection('initiatives');
                    final campsCol = FirebaseFirestore.instance.collection('campaigns');
                    final newTask = Task(
                      id: widget.task?.id ?? '',
                      title: _title,
                      description: _description,
                      status: _status,
                      dueDate: _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
                      assignedTo: _assignedUserId != null ? usersCol.doc(_assignedUserId) : widget.task?.assignedTo,
                      initiative: _initiativeId != null ? initsCol.doc(_initiativeId) : widget.task?.initiative,
                      campaign: _campaignId != null ? campsCol.doc(_campaignId) : widget.task?.campaign,
                      publicVisible: _publicVisible,
                      featured: _featured,
                    );
                    await provider.saveTask(newTask);
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
