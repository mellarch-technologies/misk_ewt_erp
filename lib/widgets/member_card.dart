// lib/widgets/member_card.dart
import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../theme/app_theme.dart' show MiskTheme;

class MemberCard extends StatelessWidget {
  final MemberModel member;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const MemberCard({super.key, required this.member, this.onTap, this.onEdit});

  Color _roleColor() {
    switch (member.role) {
      case MemberRole.trustee:
        return MiskTheme.miskGold;
      case MemberRole.admin:
        return MiskTheme.miskDarkGreen;
      case MemberRole.staff:
        return MiskTheme.miskLightGreen;
      default:
        return MiskTheme.miskCream;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colour = _roleColor();

    return Card(
      elevation: MiskTheme.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(MiskTheme.spacingMedium),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colour,
                child: Text(member.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: MiskTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: Theme.of(context).textTheme.bodyLarge),
                    Text(member.role.name.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colour)),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit, color: colour),
            ],
          ),
        ),
      ),
    );
  }
}
