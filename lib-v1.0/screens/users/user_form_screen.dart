import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/role_model.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import 'package:collection/collection.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;
  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _email, _password;
  String? _phone, _address, _designation, _occupation, _gender, _photo, _qualification, _status;
  DocumentReference? _selectedRoleId;
  bool _superAdmin = false, _allowPhoto = false;

  List<Role> _availableRoles = [];
  bool _isLoadingRoles = true;
  bool _isSaving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = u?.name ?? '';
    _email = u?.email ?? '';
    _phone = u?.phone;
    _address = u?.address;
    _designation = u?.designation;
    _occupation = u?.occupation;
    _gender = u?.gender;
    _photo = u?.photo;
    _qualification = u?.qualification;
    _status = u?.status;
    _superAdmin = u?.isSuperAdmin ?? false;
    _allowPhoto = u?.allowPhotoUpload ?? false;

    _loadRoles().then((_) {
      // Set initial role selection
      if (u?.roleId != null && _availableRoles.any((role) => role.id == u!.roleId!.id)) {
        _selectedRoleId = u!.roleId!;
      } else if (_availableRoles.isNotEmpty) {
        _selectedRoleId = FirebaseFirestore.instance
            .collection('roles')
            .doc(_availableRoles.firstWhereOrNull((role) => role.id == 'member')?.id ?? _availableRoles.first.id);
      }
      setState(() {
        _isLoadingRoles = false;
      });
    });
  }

  Future<void> _loadRoles() async {
    try {
      final query = await FirebaseFirestore.instance.collection('roles').get();
      _availableRoles = query.docs
          .map((doc) => Role.fromFirestore(doc.data(), doc.id))
          .toList();
      _availableRoles.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      print("Error loading roles: $e");
    }
  }

  Future<String?> _createAuthAndFirestoreUser(UserModel user, String password) async {
    try {
      final credentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );
      final firebaseUid = credentials.user?.uid;
      if (firebaseUid == null) return "Failed to create Auth account.";
      await FirebaseFirestore.instance.collection('users').doc(firebaseUid).set(user.toJson());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Add User' : 'Edit User'),
        backgroundColor: MiskTheme.miskDarkGreen,
        foregroundColor: MiskTheme.miskWhite,
      ),
      body: _isLoadingRoles
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(MiskTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_errorMsg != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                ),
              ],
              // --- BASIC INFO ---
              const _FormSectionHeader('Basic Information'),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Valid email is required' : null,
                onSaved: (v) => _email = v!.trim(),
                enabled: widget.user == null,
              ),
              const SizedBox(height: 16),
              if (widget.user == null)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Temporary Password'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                  onSaved: (v) => _password = v!,
                ),
              if (widget.user == null)
                const SizedBox(height: 16),
              // --- ORGANIZATION INFO ---
              const _FormSectionHeader('Role & Organization'),
              DropdownButtonFormField<DocumentReference>(
                initialValue: _selectedRoleId,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _availableRoles
                    .map((role) => DropdownMenuItem(
                  value: FirebaseFirestore.instance.collection('roles').doc(role.id),
                  child: Text(role.name.toUpperCase()),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoleId = v!),
                validator: (v) => v == null ? 'Role is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _designation ?? '',
                decoration: const InputDecoration(labelText: 'Designation'),
                onSaved: (v) => _designation = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _occupation ?? '',
                decoration: const InputDecoration(labelText: 'Occupation'),
                onSaved: (v) => _occupation = v,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Super Admin'),
                value: _superAdmin,
                onChanged: (v) => setState(() => _superAdmin = v!),
              ),
              // CONTACT DETAILS
              const _FormSectionHeader('Contact Details'),
              TextFormField(
                initialValue: _phone ?? '',
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _address ?? '',
                decoration: const InputDecoration(labelText: 'Address'),
                onSaved: (v) => _address = v,
              ),
              // PROFILE DETAILS
              const _FormSectionHeader('Profile & Status'),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v),
                onSaved: (v) => _gender = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _status ?? '',
                decoration: const InputDecoration(labelText: 'Status (Active, Inactive, etc.)'),
                onSaved: (v) => _status = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _qualification ?? '',
                decoration: const InputDecoration(labelText: 'Qualification'),
                onSaved: (v) => _qualification = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _photo ?? '',
                decoration: const InputDecoration(labelText: 'Photo URL'),
                onSaved: (v) => _photo = v,
              ),
              CheckboxListTile(
                title: const Text('Allow Photo Upload'),
                value: _allowPhoto,
                onChanged: (v) => setState(() => _allowPhoto = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();
                  setState(() {
                    _isSaving = true;
                    _errorMsg = null;
                  });

                  final u = UserModel(
                    uid: widget.user?.uid ?? '',
                    name: _name,
                    email: _email,
                    roleId: _selectedRoleId,
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

                  String? err;
                  if (widget.user == null) {
                    err = await _createAuthAndFirestoreUser(u, _password);
                  } else {
                    await prov.saveUser(u);
                  }

                  setState(() => _isSaving = false);

                  if (err != null) {
                    setState(() => _errorMsg = err);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $err')),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(widget.user == null ? "Add User" : "Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Section Header Helper ---
class _FormSectionHeader extends StatelessWidget {
  final String title;
  const _FormSectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24.0, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
    ),
  );
}
