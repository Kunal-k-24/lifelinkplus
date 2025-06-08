import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  Position? _currentPosition;
  final List<Hospital> _nearbyHospitals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _nearbyHospitals.addAll(_getDummyHospitals(position));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  List<Hospital> _getDummyHospitals(Position userPosition) {
    // Generate dummy hospitals around user's location
    return [
      Hospital(
        name: 'City General Hospital',
        address: '123 Healthcare Ave',
        phoneNumber: '+1234567890',
        latitude: userPosition.latitude + 0.01,
        longitude: userPosition.longitude + 0.01,
        distance: 1.2,
      ),
      Hospital(
        name: 'Community Medical Center',
        address: '456 Medical Drive',
        phoneNumber: '+1234567891',
        latitude: userPosition.latitude - 0.01,
        longitude: userPosition.longitude - 0.01,
        distance: 0.8,
      ),
      Hospital(
        name: 'Emergency Care Hospital',
        address: '789 Emergency Road',
        phoneNumber: '+1234567892',
        latitude: userPosition.latitude + 0.02,
        longitude: userPosition.longitude - 0.02,
        distance: 2.1,
      ),
    ];
  }

  Future<void> _launchMaps(Hospital hospital) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Hospitals'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? const Center(
                  child: Text('Unable to get location. Please enable location services.'),
                )
              : ListView.builder(
                  itemCount: _nearbyHospitals.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final hospital = _nearbyHospitals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hospital.address,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              'Distance: ${hospital.distance.toStringAsFixed(1)} km',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchMaps(hospital),
                                    icon: const Icon(Icons.directions),
                                    label: const Text('Directions'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchPhone(hospital.phoneNumber),
                                    icon: const Icon(Icons.phone),
                                    label: const Text('Call'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class Hospital {
  final String name;
  final String address;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final double distance;

  Hospital({
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });
} 