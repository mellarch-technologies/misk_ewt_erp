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
    DocumentReference? roleRef;
    final roleIdRaw = json['roleId'];
    if (roleIdRaw is DocumentReference) {
      roleRef = roleIdRaw;
    } else if (roleIdRaw is String && roleIdRaw.isNotEmpty) {
      final segments = roleIdRaw.split('/');
      final roleDocId = segments.length == 2 ? segments[1] : roleIdRaw;
      roleRef = FirebaseFirestore.instance.collection('roles').doc(roleDocId);
    }

    DateTime? createdAt;
    final createdAtRaw = json['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return UserModel(
      uid: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleId: roleRef,
      isSuperAdmin: json['isSuperAdmin'] ?? false,
      designation: json['designation'] as String?,
      occupation: json['occupation'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      allowPhotoUpload: json['allowPhotoUpload'] ?? false,
      createdAt: createdAt,
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
    // Trim whitespace and split the name into parts.
    // Filter out empty strings that might result from multiple spaces.
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) {
      return '?'; // Or an empty string, depending on desired behavior
    }
    if (parts.length == 1) {
      // If only one part, take the first character of that part.
      return parts.first[0].toUpperCase();
    } else {
      // If multiple parts, take the first character of the first part
      // and the first character of the last part.
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
  }
}
