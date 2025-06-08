import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'hospital.freezed.dart';
part 'hospital.g.dart';

@freezed
class Hospital with _$Hospital {
  const factory Hospital({
    required String id,
    required String name,
    required String address,
    required String phoneNumber,
    required double latitude,
    required double longitude,
    String? imageUrl,
    String? description,
    @Default(false) bool isOpen24Hours,
  }) = _Hospital;

  factory Hospital.fromJson(Map<String, dynamic> json) => _$HospitalFromJson(json);
}

// This is a utility extension to get LatLng for Google Maps
extension HospitalLocation on Hospital {
  LatLng get location => LatLng(latitude, longitude);
} 