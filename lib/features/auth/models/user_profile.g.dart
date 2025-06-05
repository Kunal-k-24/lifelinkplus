// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      uid: json['uid'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      age: (json['age'] as num).toInt(),
      gender: json['gender'] as String,
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      bloodGroup: json['bloodGroup'] as String,
      allergies:
          (json['allergies'] as List<dynamic>).map((e) => e as String).toList(),
      medicalConditions: (json['medicalConditions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      photoUrl: json['photoUrl'] as String?,
      createdAt: _timestampToDateTime(json['createdAt'] as Timestamp),
      updatedAt: _timestampToDateTime(json['updatedAt'] as Timestamp),
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'fullName': instance.fullName,
      'email': instance.email,
      'age': instance.age,
      'gender': instance.gender,
      'height': instance.height,
      'weight': instance.weight,
      'bloodGroup': instance.bloodGroup,
      'allergies': instance.allergies,
      'medicalConditions': instance.medicalConditions,
      'photoUrl': instance.photoUrl,
      'createdAt': _dateTimeToTimestamp(instance.createdAt),
      'updatedAt': _dateTimeToTimestamp(instance.updatedAt),
    };
