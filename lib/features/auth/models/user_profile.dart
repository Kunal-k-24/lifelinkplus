import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

DateTime _timestampToDateTime(Timestamp timestamp) =>
    timestamp.toDate();

Timestamp _dateTimeToTimestamp(DateTime dateTime) =>
    Timestamp.fromDate(dateTime);

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String fullName,
    required String email,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String bloodGroup,
    required List<String> allergies,
    required List<String> medicalConditions,
    String? photoUrl,
    @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
    required DateTime createdAt,
    @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
    required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
} 