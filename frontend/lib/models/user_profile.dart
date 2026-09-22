// frontend/lib/models/user_profile.dart

import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String storeName;
  final String ownerName;
  final String phoneNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final DateTime createdAt;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.storeName,
    required this.ownerName,
    required this.phoneNumber,
    this.email,
    this.address,
    this.city,
    this.state,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? storeName,
    String? ownerName,
    String? phoneNumber,
    String? email,
    String? address,
    String? city,
    String? state,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  String get displayPhone => phoneNumber.length > 4
      ? 'XXXXX${phoneNumber.substring(phoneNumber.length - 4)}'
      : phoneNumber;
}
