// lib/screens/users/user_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;
  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _email, _phone, _address, _designation, _occupation,
      _gender, _photo, _qualification, _status;
  late UserRole _role;
  bool _superAdmin = false, _allowPhoto = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = u?.name ?? '';
    _email = u?.email ?? '';
    _phone = u?.phone ?? '';
    _address = u?.address ?? '';
    _designation = u?.designation ?? '';
    _occupation = u?.occupation ?? '';
    _gender = u?.gender ?? '';
    _photo = u?.photo ?? '';
    _qualification = u?.qualification ?? '';
    _status = u?.status ?? '';
    _role = u?.role ?? UserRole.member;
    _superAdmin = u?.isSuperAdmin ?? false;
    _allowPhoto = u?.allowPhotoUpload ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(MiskTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                v == null || !v.contains('@') ? 'Valid email' : null,
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name.toUpperCase()),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Super Admin'),
                value: _superAdmin,
                onChanged: (v) => setState(() => _superAdmin = v!),
              ),
              CheckboxListTile(
                title: const Text('Allow Photo Upload'),
                value: _allowPhoto,
                onChanged: (v) => setState(() => _allowPhoto = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final u = UserModel(
                      uid: widget.user?.uid ?? '',
                      name: _name,
                      email: _email,
                      role: _role,
                      isSuperAdmin: _superAdmin,
                      phone: _phone,
                      address: _address,
                      designation: _designation,
                      occupation: _occupation,
                      gender: _gender,
                      photo: _photo,
                      qualification: _qualification,
                      status: _status,
                      allowPhotoUpload: _allowPhoto,
                      createdAt: widget.user?.createdAt,
                    );
                    prov.saveUser(u);
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
