import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lifelink/features/hospitals/models/hospital.dart';

final hospitalsProvider = StateNotifierProvider<HospitalsNotifier, List<Hospital>>((ref) {
  return HospitalsNotifier();
});

class HospitalsNotifier extends StateNotifier<List<Hospital>> {
  HospitalsNotifier() : super([]);

  // Dummy data for hospitals (since we're not using an API)
  final List<Hospital> _dummyHospitals = [
    Hospital(
      id: '1',
      name: 'City General Hospital',
      address: '123 Healthcare Ave',
      phoneNumber: '+1234567890',
      latitude: 0.0, // Will be updated based on user location
      longitude: 0.0,
      description: 'Full-service general hospital with 24/7 emergency care',
      isOpen24Hours: true,
    ),
    Hospital(
      id: '2',
      name: 'Community Medical Center',
      address: '456 Medical Drive',
      phoneNumber: '+1234567891',
      latitude: 0.0,
      longitude: 0.0,
      description: 'Community focused healthcare facility',
      isOpen24Hours: false,
    ),
    Hospital(
      id: '3',
      name: 'Emergency Care Hospital',
      address: '789 Emergency Road',
      phoneNumber: '+1234567892',
      latitude: 0.0,
      longitude: 0.0,
      description: '24/7 emergency services available',
      isOpen24Hours: true,
    ),
  ];

  Future<void> loadNearbyHospitals() async {
    try {
      // Get current location
      final position = await _getCurrentLocation();
      
      // Update hospital locations relative to user's position
      final hospitals = _dummyHospitals.map((hospital) {
        // Create some variation in hospital locations around the user
        final latOffset = (hospital.id.hashCode % 10) / 100;
        final lngOffset = (hospital.id.hashCode % 7) / 100;
        
        return hospital.copyWith(
          latitude: position.latitude + latOffset,
          longitude: position.longitude + lngOffset,
        );
      }).toList();

      state = hospitals;
    } catch (e) {
      // Handle errors appropriately
      state = [];
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }
} 