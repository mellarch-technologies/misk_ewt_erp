import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';

import '../../models/user_model.dart';
import '../../models/role_model.dart';
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

  late String _name, _email, _password;
  String? _phone, _address, _designation, _occupation, _gender,
      _photo, _qualification, _status;

  String? _selectedRoleDocId; // store only the role doc ID
  bool _superAdmin = false, _allowPhoto = false;

  List<Role> _availableRoles = [];
  bool _isLoadingRoles = true;
  bool _isSaving = false;
  String? _errorMsg;

  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeFromUser(widget.user);
    _loadRoles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserModel && args != _currentUser) {
      _initializeFromUser(args);
      _loadRoles();
    }
  }

  void _initializeFromUser(UserModel? u) {
    _currentUser = u;
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
    _selectedRoleDocId = u?.roleId?.id;
  }

  Future<void> _loadRoles() async {
    try {
      final query = await FirebaseFirestore.instance.collection('roles').get();
      final seen = <String>{};
      _availableRoles = query.docs
          .map((doc) => Role.fromFirestore(doc.data(), doc.id))
          .where((r) => seen.add(r.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      // Ensure selection is valid
      if (_selectedRoleDocId == null ||
          !_availableRoles.any((r) => r.id == _selectedRoleDocId)) {
        _selectedRoleDocId = _availableRoles.isNotEmpty
            ? _availableRoles
            .firstWhereOrNull((r) => r.id == 'member')
            ?.id ?? _availableRoles.first.id
            : null;
      }
    } finally {
      if (mounted) setState(() => _isLoadingRoles = false);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser == null ? 'Add User' : 'Edit User'),
        backgroundColor: MiskTheme.miskDarkGreen,
        foregroundColor: MiskTheme.miskWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar with initials
              CircleAvatar(
                radius: 48,
                backgroundColor: MiskTheme.miskGold.withAlpha(38),
                child: Text(
                  _name.isNotEmpty
                      ? _name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 36,
                      color: MiskTheme.miskDarkGreen,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                    labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name required' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email)),
                validator: (v) =>
                v == null || !v.contains('@') ? 'Valid email required' : null,
                onSaved: (v) => _email = v!.trim(),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              if (_currentUser == null)
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (v) =>
                  v == null || v.length < 6 ? 'Min 6 characters' : null,
                  onSaved: (v) => _password = v!,
                ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(
                    labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                onSaved: (v) => _phone = v,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(
                    labelText: 'Address', prefixIcon: Icon(Icons.home)),
                onSaved: (v) => _address = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _designation,
                decoration: const InputDecoration(
                    labelText: 'Designation', prefixIcon: Icon(Icons.badge)),
                onSaved: (v) => _designation = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _occupation,
                decoration: const InputDecoration(
                    labelText: 'Occupation', prefixIcon: Icon(Icons.work)),
                onSaved: (v) => _occupation = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _qualification,
                decoration: const InputDecoration(
                    labelText: 'Qualification', prefixIcon: Icon(Icons.school)),
                onSaved: (v) => _qualification = v,
              ),
              const SizedBox(height: 16),

              // ✅ Role Dropdown with guard
              if (_isLoadingRoles)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  initialValue: (_selectedRoleDocId != null &&
                      _availableRoles.any((r) => r.id == _selectedRoleDocId))
                      ? _selectedRoleDocId
                      : null,
                  decoration: const InputDecoration(
                      labelText: 'Role', prefixIcon: Icon(Icons.security)),
                  items: _availableRoles
                      .map((r) => DropdownMenuItem<String>(
                    value: r.id,
                    child: Text(r.name),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRoleDocId = v),
                  onSaved: (v) => _selectedRoleDocId = v,
                  isExpanded: true,
                ),

              const SizedBox(height: 16),
              /*DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                    labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                onSaved: (v) => _gender = v,
              ),*/
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _status,
                decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.verified_user)),
                onSaved: (v) => _status = v,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                value: _allowPhoto,
                onChanged: (v) => setState(() => _allowPhoto = v),
                title: const Text('Allow Photo Upload'),
              ),
              CheckboxListTile(
                value: _superAdmin,
                onChanged: (v) => setState(() => _superAdmin = v ?? false),
                title: const Text('Super Admin'),
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(_errorMsg!,
                    style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.save),
                label: Text(_currentUser == null ? 'Create User' : 'Save Changes'),
                onPressed: _isSaving ? null : () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MiskTheme.miskGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });

    final roleRef = (_selectedRoleDocId != null)
        ? FirebaseFirestore.instance.collection('roles').doc(_selectedRoleDocId)
        : null;

    final u = UserModel(
      uid: _currentUser?.uid ?? '',
      name: _name,
      email: _email,
      roleId: roleRef,
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
      createdAt: _currentUser?.createdAt,
    );

    String? err;
    if (_currentUser == null) {
      err = await _createAuthAndFirestoreUser(u, _password);
    } else {
      try {
        await context.read<UserProvider>().saveUser(u);
      } catch (e) {
        err = e.toString();
      }
    }

    setState(() => _isSaving = false);

    if (err != null) {
      setState(() => _errorMsg = err);
    } else if (mounted) {
      Navigator.pop(context);
    }
  }
}
