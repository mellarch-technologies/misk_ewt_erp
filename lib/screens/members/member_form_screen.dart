// lib/screens/members/member_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/member_model.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_theme.dart' show MiskTheme;

class MemberFormScreen extends StatefulWidget {
  final MemberModel? member;
  const MemberFormScreen({super.key, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _email;
  MemberRole _role = MemberRole.member;
  bool _superAdmin = false;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _name = widget.member!.name;
      _email = widget.member!.email;
      _role = widget.member!.role;
      _superAdmin = widget.member!.isSuperAdmin;
    } else {
      _name = '';
      _email = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MemberProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.member == null ? 'Add Member' : 'Edit Member')),
      body: Padding(
        padding: EdgeInsets.all(MiskTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              const SizedBox(height: MiskTheme.spacingMedium),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: MiskTheme.spacingMedium),
              DropdownButtonFormField<MemberRole>(
                value: _role,
                items: MemberRole.values
                    .map((r) =>
                    DropdownMenuItem(value: r, child: Text(r.name.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: MiskTheme.spacingMedium),
              CheckboxListTile(
                title: const Text('Super-Admin Trustee'),
                value: _superAdmin,
                onChanged: (v) => setState(() => _superAdmin = v!),
              ),
              const SizedBox(height: MiskTheme.spacingLarge),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    prov.save(
                      MemberModel(
                        uid: widget.member?.uid ?? '',
                        name: _name,
                        email: _email,
                        role: _role,
                        isSuperAdmin: _superAdmin,
                      ),
                    );
                    Navigator.pop(context);
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
