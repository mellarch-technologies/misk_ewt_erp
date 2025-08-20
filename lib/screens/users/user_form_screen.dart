import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../models/user_model.dart';
import '../../models/role_model.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/photo_service.dart';
import '../../services/app_config.dart';
import '../../services/photo_repository.dart';
import '../../widgets/snackbar_helper.dart';

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
  bool _allowPhotoOverridden = false;
  bool _isUploadingPhoto = false;

  List<Role> _availableRoles = [];
  bool _isLoadingRoles = true;
  bool _isSaving = false;
  String? _errorMsg;

  UserModel? _currentUser;

  static const List<String> _genders = ['Male', 'Female', 'Other'];

  String? _normalizeGender(String? g) {
    if (g == null) return null;
    final t = g.trim();
    if (t.isEmpty) return null;
    // Exact (case-insensitive) match first
    final match = _genders.firstWhere(
      (e) => e.toLowerCase() == t.toLowerCase(),
      orElse: () => '',
    );
    if (match.isNotEmpty) return match;
    // Common aliases
    final lower = t.toLowerCase();
    if (lower == 'm' || lower == 'male') return 'Male';
    if (lower == 'f' || lower == 'female') return 'Female';
    if (lower == 'o' || lower == 'other' || lower == 'others') return 'Other';
    return null; // fallback: no initial selection
  }

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
    _gender = _normalizeGender(u?.gender);
    _photo = u?.photo;
    _qualification = u?.qualification;
    _status = u?.status;
    _superAdmin = u?.isSuperAdmin ?? false;
    _allowPhoto = u?.allowPhotoUpload ?? false;
    _allowPhotoOverridden = false; // respect stored value; user can override in UI
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

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1) const SizedBox(height: 16),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
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
              // Photo preview + actions
              _section('Photo', [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: MiskTheme.miskGold.withAlpha(38),
                      backgroundImage: (_photo != null && _photo!.startsWith('http'))
                          ? NetworkImage(_photo!)
                          : null,
                      child: (_photo != null && _photo!.startsWith('http'))
                          ? null
                          : Text(
                              _name.isNotEmpty
                                  ? _name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: MiskTheme.miskDarkGreen,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_allowPhoto)
                            ElevatedButton.icon(
                              onPressed: _isSaving || _isUploadingPhoto ? null : _uploadPhotoFlow,
                              icon: _isUploadingPhoto
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.upload),
                              label: Text(_isUploadingPhoto ? 'Uploading…' : 'Upload Photo'),
                            ),
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _promptPhotoUrl,
                            icon: const Icon(Icons.link),
                            label: const Text('Set Photo URL'),
                          ),
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() => _photo = null); // Use generated avatar on save
                                  },
                            child: const Text('Use Generated Avatar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),

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

              // Sections
              _section('Basic Info', [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                  onSaved: (v) => _name = v!.trim(),
                ),
                TextFormField(
                  initialValue: _email,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                  onSaved: (v) => _email = v!.trim(),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (_currentUser == null)
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                    onSaved: (v) => _password = v!,
                  ),
              ]),

              _section('Contact', [
                TextFormField(
                  initialValue: _phone,
                  decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                  onSaved: (v) => _phone = v,
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  initialValue: _address,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home)),
                  onSaved: (v) => _address = v,
                ),
              ]),

              _section('Work', [
                TextFormField(
                  initialValue: _designation,
                  decoration: const InputDecoration(labelText: 'Designation', prefixIcon: Icon(Icons.badge)),
                  onSaved: (v) => _designation = v,
                ),
                TextFormField(
                  initialValue: _occupation,
                  decoration: const InputDecoration(labelText: 'Occupation', prefixIcon: Icon(Icons.work)),
                  onSaved: (v) => _occupation = v,
                ),
                TextFormField(
                  initialValue: _qualification,
                  decoration: const InputDecoration(labelText: 'Qualification', prefixIcon: Icon(Icons.school)),
                  onSaved: (v) => _qualification = v,
                ),
              ]),

              _section('Role & Access', [
                if (_isLoadingRoles)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String>(
                    initialValue: (_selectedRoleDocId != null && _availableRoles.any((r) => r.id == _selectedRoleDocId)) ? _selectedRoleDocId : null,
                    decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.security)),
                    items: _availableRoles
                        .map((r) => DropdownMenuItem<String>(value: r.id, child: Text('${r.name}${r.description != null && r.description!.isNotEmpty ? ' — ${r.description}' : ''}')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRoleDocId = v),
                    onSaved: (v) => _selectedRoleDocId = v,
                    isExpanded: true,
                  ),
                SwitchListTile(
                  value: _allowPhoto,
                  onChanged: (v) => setState(() { _allowPhotoOverridden = true; _allowPhoto = v; }),
                  title: const Text('Allow Photo Upload'),
                  subtitle: const Text('Default: allowed for Male; override as needed'),
                ),
                CheckboxListTile(
                  value: _superAdmin,
                  onChanged: (v) => setState(() => _superAdmin = v ?? false),
                  title: const Text('Super Admin'),
                ),
              ]),

              _section('Personal', [
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
                  items: _genders
                      .map((g) => DropdownMenuItem<String>(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() { _gender = v; if (!_allowPhotoOverridden) { _allowPhoto = (v == 'Male'); } }),
                  onSaved: (v) => _gender = v,
                ),
                TextFormField(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.verified_user)),
                  onSaved: (v) => _status = v,
                ),
              ]),

              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

  Future<void> _promptPhotoUrl() async {
    final controller = TextEditingController(text: _photo ?? '');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Photo URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://example.com/photo.jpg'),
          keyboardType: TextInputType.url,
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (url != null) {
      setState(() => _photo = url.isEmpty ? null : url);
    }
  }

  Future<void> _uploadPhotoFlow() async {
    if (!_allowPhoto) {
      SnackbarHelper.showInfo(context, 'Photo upload not allowed for this user');
      return;
    }
    try {
      setState(() => _isUploadingPhoto = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return; // user canceled
      }
      Uint8List bytes = await picked.readAsBytes();
      // Compress to reasonable size/quality
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 512,
        minHeight: 512,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      final repo = getPhotoRepository(AppConfig.photoStorage);
      final url = await repo.upload(
        compressed,
        fileName: 'user_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );
      setState(() => _photo = url);
      if (mounted) SnackbarHelper.showSuccess(context, 'Photo uploaded');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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

    final effectivePhoto = (_photo == null || _photo!.trim().isEmpty)
        ? PhotoService.avatarUrlForName(_name)
        : _photo!.trim();

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
      photo: effectivePhoto,
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
