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

  Color _roleColor() {
    switch (user.role) {
      case UserRole.trustee:
        return MiskTheme.miskGold;
      case UserRole.admin:
        return MiskTheme.miskDarkGreen;
      case UserRole.staff:
        return MiskTheme.miskLightGreen;
      default:
        return MiskTheme.miskCream;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor();
    return Card(
      elevation: MiskTheme.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(user.initials, style: const TextStyle(color: Colors.white)),
        ),
        title: Text(user.name),
        subtitle: Text(user.role.name.toUpperCase()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(icon: const Icon(Icons.edit), color: color, onPressed: onEdit),
            if (onDelete != null)
              IconButton(icon: const Icon(Icons.delete), color: Colors.red, onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
