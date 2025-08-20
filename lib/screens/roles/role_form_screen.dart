// lib/screens/roles/role_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/role_model.dart';
import '../../providers/role_provider.dart';
import '../../providers/app_auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/security_service.dart';
import '../../widgets/snackbar_helper.dart';

class RoleFormScreen extends StatefulWidget {
  final Role? role;
  const RoleFormScreen({super.key, this.role});

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String? _description;
  late Map<String, bool> _permissions;
  bool _isSaving = false;
  String? _errorMsg;

  // Default permissions (add more as needed)
  static const List<String> _allPermissions = [
    'can_manage_users',
    'can_view_finances',
    'can_manage_events',
    'can_view_reports',
    'can_edit_profile',
    'can_manage_roles',
  ];

  List<String> _dynamicPermissions = [];

  Future<void> _fetchDynamicPermissions() async {
    try {
      // Fetch permissions from Firestore 'permissions' collection
      final snapshot = await FirebaseFirestore.instance.collection('permissions').get();
      final perms = snapshot.docs.map((doc) => doc['key'] as String).toList();
      setState(() {
        _dynamicPermissions = perms.isNotEmpty ? perms : _allPermissions;
      });
    } catch (e) {
      setState(() {
        _dynamicPermissions = _allPermissions;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDynamicPermissions();
    _name = widget.role?.name ?? '';
    _description = widget.role?.description ?? '';

    // Initialize permissions with proper typing
    _permissions = <String, bool>{};
    if (widget.role?.permissions != null) {
      for (var entry in widget.role!.permissions.entries) {
        _permissions[entry.key] = entry.value == true;
      }
    }

    // Ensure all default permissions are present
    for (var p in _allPermissions) {
      _permissions.putIfAbsent(p, () => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == null ? 'Add Role' : 'Edit Role'),
        // rely on theme for AppBar colors
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                ),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Role Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Role name is required' : null,
                onSaved: (v) => _name = v!.trim(),
                enabled: widget.role?.protected != true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                onSaved: (v) => _description = v,
                enabled: widget.role?.protected != true,
              ),
              const SizedBox(height: 24),
              const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ...(_dynamicPermissions.isNotEmpty ? _dynamicPermissions : _allPermissions).map((perm) => CheckboxListTile(
                title: Text(_permissionLabel(perm)),
                value: _permissions[perm] ?? false,
                onChanged: (v) => setState(() => _permissions[perm] = v ?? false),
              )),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();

                  // Re-authenticate before creating/updating roles
                  final ok = await const SecurityService().ensureReauthenticated(
                    context,
                    reason: widget.role == null
                        ? 'Confirm your identity to create a new role.'
                        : 'Confirm your identity to update the role "${widget.role!.name}".',
                  );
                  if (!ok) {
                    if (mounted) SnackbarHelper.showInfo(context, 'Action cancelled');
                    return;
                  }

                  setState(() {
                    _isSaving = true;
                    _errorMsg = null;
                  });

                  final role = Role(
                    id: widget.role?.id ?? '',
                    name: _name,
                    permissions: _permissions,
                    protected: widget.role?.protected ?? false,
                    description: _description,
                    createdBy: widget.role?.createdBy,
                    updatedBy: widget.role?.updatedBy,
                    createdAt: widget.role?.createdAt,
                    updatedAt: widget.role?.updatedAt,
                  );

                  try {
                    // Get current user ID from auth provider
                    final currentUserId = context.read<AppAuthProvider>().user?.uid ?? 'system';

                    if (widget.role == null) {
                      await roleProvider.addRole(role, currentUserId: currentUserId);
                    } else {
                      await roleProvider.updateRole(role, currentUserId: currentUserId);
                    }

                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    setState(() => _errorMsg = e.toString());
                  } finally {
                    setState(() => _isSaving = false);
                  }
                },
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(widget.role == null ? 'Add Role' : 'Save'),
              ),
              if (widget.role != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const Text('Audit Info', style: TextStyle(fontWeight: FontWeight.bold)),
                if (widget.role!.createdBy != null)
                  Text('Created by: ${widget.role!.createdBy}'),
                if (widget.role!.createdAt != null)
                  Text('Created at: ${widget.role!.createdAt}'),
                if (widget.role!.updatedBy != null)
                  Text('Updated by: ${widget.role!.updatedBy}'),
                if (widget.role!.updatedAt != null)
                  Text('Updated at: ${widget.role!.updatedAt}'),
                if (widget.role!.protected)
                  const Text('System Role (protected)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _permissionLabel(String key) {
    switch (key) {
      case 'can_manage_users':
        return 'Manage Users';
      case 'can_view_finances':
        return 'View Finances';
      case 'can_manage_events':
        return 'Manage Events';
      case 'can_view_reports':
        return 'View Reports';
      case 'can_edit_profile':
        return 'Edit Profile';
      case 'can_manage_roles':
        return 'Manage Roles';
      default:
        return key;
    }
  }
}
