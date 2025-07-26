// lib/models/user_model

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { trustee, admin, staff, member, associate }

UserRole userRoleFromString(String r) =>
    UserRole.values.firstWhere((e) => e.name == r, orElse: () => UserRole.member);

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool isSuperAdmin;
  final String? designation;
  final String? occupation;
  final String? phone;
  final String? address;
  final bool allowPhotoUpload;
  final DateTime? createdAt;
  final String? gender;
  final String? photo;
  final String? qualification;
  final String? status;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isSuperAdmin = false,
    this.designation,
    this.occupation,
    this.phone,
    this.address,
    this.allowPhotoUpload = false,
    this.createdAt,
    this.gender,
    this.photo,
    this.qualification,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      uid: id,
      name: json['Name'] ?? '',
      email: json['Email'] ?? '',
      role: userRoleFromString(json['Role'] ?? 'member'),
      isSuperAdmin: json['IsSuperAdmin'] as bool? ?? false,
      designation: json['Designation'] as String?,
      occupation: json['Occupation'] as String?,
      phone: json['Phone'] as String?,
      address: json['Address'] as String?,
      allowPhotoUpload: json['AllowPhotoUpload'] as bool? ?? false,
      createdAt: (json['CreatedAt'] as Timestamp ?)?.toDate(),
      gender: json['Gender'] as String?,
      photo: json['Photo'] as String?,
      qualification: json['Qualification'] as String?,
      status: json['Status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'Name': name,
    'Email': email,
    'Role': role.name,
    'IsSuperAdmin': isSuperAdmin,
    if (designation != null) 'Designation': designation,
    if (occupation != null) 'Occupation': occupation,
    if (phone != null) 'Phone': phone,
    if (address != null) 'Address': address,
    'AllowPhotoUpload': allowPhotoUpload,
    'CreatedAt': createdAt,
    if (gender != null) 'Gender': gender,
    if (photo != null) 'Photo': photo,
    if (qualification != null) 'Qualification': qualification,
    if (status != null) 'Status': status,
  };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0];
    return parts[0][0] + parts[1][0];
  }
}
