// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DocumentReference? roleId;
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
    this.roleId,
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
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleId: json['roleId'] as DocumentReference?,
      isSuperAdmin: json['isSuperAdmin'] ?? false,
      designation: json['designation'] as String?,
      occupation: json['occupation'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      allowPhotoUpload: json['allowPhotoUpload'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      gender: json['gender'] as String?,
      photo: json['photo'] as String?,
      qualification: json['qualification'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'roleId': roleId,
    'isSuperAdmin': isSuperAdmin,
    if (designation != null) 'designation': designation,
    if (occupation != null) 'occupation': occupation,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    'allowPhotoUpload': allowPhotoUpload,
    'createdAt': createdAt,
    if (gender != null) 'gender': gender,
    if (photo != null) 'photo': photo,
    if (qualification != null) 'qualification': qualification,
    if (status != null) 'status': status,
  };

  // Add the initials getter back to UserModel
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0];
    return parts[0][0] + parts[1][0];
  }
}
