import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/initiative_model.dart';

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

  @override
  void initState() {
    super.initState();
    _title = widget.initiative?.title ?? '';
    _description = widget.initiative?.description;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.initiative == null ? 'Add Initiative' : 'Edit Initiative')),
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
                    final newInitiative = Initiative(
                      id: widget.initiative?.id ?? '',
                      title: _title,
                      description: _description,
                    );
                    await provider.saveInitiative(newInitiative);
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
