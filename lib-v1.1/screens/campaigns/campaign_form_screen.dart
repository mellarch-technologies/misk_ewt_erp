import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign_model.dart';
import '../../providers/campaign_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _name = widget.campaign?.name ?? '';
    _description = widget.campaign?.description;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CampaignProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.campaign == null ? 'Add Campaign' : 'Edit Campaign')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v ?? '',
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
                    final newCampaign = Campaign(
                      id: widget.campaign?.id ?? '',
                      name: _name,
                      description: _description,
                    );
                    await provider.saveCampaign(newCampaign);
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

