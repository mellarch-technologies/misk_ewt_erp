// lib/widgets/user_card.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    this.onEdit,
    this.onDelete,
  });

  // Determine color based on roleId (can map to specific role names/IDs)
  // This is a simplified example; you might fetch the role.name from the document
  // or define a mapping based on roleId.id (the string ID like 'super_admin', 'trustee').
  Color _getRoleColor(String roleIdString) {
    switch (roleIdString) {
      case 'trustee':
        return MiskTheme.miskGold;
      case 'admin': // Assuming 'admin' is a roleId string
        return MiskTheme.miskDarkGreen;
      case 'staff':
        return MiskTheme.miskLightGreen;
      case 'super_admin': // Handle super admin explicitly if you want a distinct color
        return Colors.purple.shade700; // Or any distinct color
      default:
        return MiskTheme.miskCream; // Default for 'member' or unknown
    }
  }

  @override
  Widget build(BuildContext context) {
    // We can get the human-readable role name from the PermissionProvider if needed,
    // or rely on a local mapping. For simplicity, we'll use user.roleId.id.
    final roleIdString = user.roleId?.id ?? 'member'; // Get the string ID from DocumentReference
    final color = _getRoleColor(roleIdString);

    return Card(
      elevation: MiskTheme.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(user.initials, style: const TextStyle(color: Colors.white)), // Use the 'initials' getter
        ),
        title: Text(user.name),
        // Display the roleId string, capitalized. Consider fetching role name for better UX.
        // For now, this will display "TRUSTEE", "ADMIN", etc.
        subtitle: Text(roleIdString.toUpperCase()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(icon: const Icon(Icons.edit), color: MiskTheme.miskGold, onPressed: onEdit),
            if (onDelete != null)
              IconButton(icon: const Icon(Icons.delete), color: Colors.red, onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
