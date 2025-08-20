// lib/models/member_model.dart
enum MemberRole { trustee, admin, staff, member, associate }

MemberRole roleFromString(String r) =>
    MemberRole.values.firstWhere((e) => e.name == r, orElse: () => MemberRole.member);

class MemberModel {
  final String uid;
  final String name;
  final String email;
  final MemberRole role;
  final bool isSuperAdmin;

  MemberModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isSuperAdmin = false,
  });

  String get initials =>
      name.trim().isEmpty ? '?' : name.trim().split(' ').map((p) => p[0]).take(2).join();

  factory MemberModel.fromJson(Map<String, dynamic> json, String id) => MemberModel(
    uid: id,
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    role: roleFromString(json['role'] ?? 'member'),
    isSuperAdmin: json['isSuperAdmin'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'role': role.name,
    'isSuperAdmin': isSuperAdmin,
  };
}
