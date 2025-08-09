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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Add User' : 'Edit User'),
        backgroundColor: MiskTheme.miskDarkGreen,
        foregroundColor: MiskTheme.miskWhite,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar Placeholder
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: MiskTheme.miskGold.withAlpha(38),
                    child: Text(
                      _name.isNotEmpty ? _name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, color: MiskTheme.miskDarkGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Tooltip(
                    message: 'Avatar upload coming soon',
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.edit, color: Colors.grey, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                    onSaved: (v) => _name = v!.trim(),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                    onSaved: (v) => _email = v!.trim(),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  if (widget.user == null)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                      onSaved: (v) => _password = v!,
                      textInputAction: TextInputAction.next,
                    ),
                  const SizedBox(height: 24),
                  const Text('Other Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _phone,
                    decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                    onSaved: (v) => _phone = v,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _address,
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home)),
                    onSaved: (v) => _address = v,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _designation,
                    decoration: const InputDecoration(labelText: 'Designation', prefixIcon: Icon(Icons.badge)),
                    onSaved: (v) => _designation = v,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _occupation,
                    decoration: const InputDecoration(labelText: 'Occupation', prefixIcon: Icon(Icons.work)),
                    onSaved: (v) => _occupation = v,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _qualification,
                    decoration: const InputDecoration(labelText: 'Qualification', prefixIcon: Icon(Icons.school)),
                    onSaved: (v) => _qualification = v,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                    onSaved: (v) => _gender = v,
                  ),
                  const SizedBox(height: 16),
                  // Role Dropdown
                  _isLoadingRoles
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<DocumentReference>(
                          value: _selectedRoleId,
                          decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.security)),
                          items: _availableRoles
                              .map((role) => DropdownMenuItem(
                                    value: FirebaseFirestore.instance.collection('roles').doc(role.id),
                                    child: Text(role.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRoleId = v),
                          onSaved: (v) => _selectedRoleId = v,
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.verified_user)),
                    onSaved: (v) => _status = v,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile.adaptive(
                    value: _allowPhoto,
                    onChanged: (v) => setState(() => _allowPhoto = v),
                    title: const Text('Allow Photo Upload (future)'),
                    subtitle: const Text('Enable this to allow the user to upload a profile photo.'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _superAdmin,
                    onChanged: (v) => setState(() => _superAdmin = v ?? false),
                    title: const Text('Super Admin'),
                    subtitle: const Text('Grant this user super admin privileges.'),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(widget.user == null ? 'Create User' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MiskTheme.miskGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              _formKey.currentState!.save();
                              setState(() => _isSaving = true);
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
                                await Provider.of<UserProvider>(context, listen: false).saveUser(u);
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
