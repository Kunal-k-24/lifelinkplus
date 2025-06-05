import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/styled_card.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  final _hospitals = [
    {
      'name': 'City General Hospital',
      'distance': '1.2 km',
      'rating': 4.5,
      'address': '123 Medical Center Dr',
      'phone': '+1 (555) 123-4567',
      'emergency': true,
      'specialties': ['Emergency Care', 'Surgery', 'Pediatrics'],
    },
    {
      'name': 'St. Mary\'s Medical Center',
      'distance': '2.8 km',
      'rating': 4.2,
      'address': '456 Health Parkway',
      'phone': '+1 (555) 234-5678',
      'emergency': true,
      'specialties': ['Cardiology', 'Oncology', 'Neurology'],
    },
    {
      'name': 'Community Health Clinic',
      'distance': '3.5 km',
      'rating': 4.0,
      'address': '789 Wellness Ave',
      'phone': '+1 (555) 345-6789',
      'emergency': false,
      'specialties': ['Family Medicine', 'Pediatrics', 'Mental Health'],
    },
  ];

  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredHospitals {
    if (_searchQuery.isEmpty) return _hospitals;
    final query = _searchQuery.toLowerCase();
    return _hospitals.where((hospital) {
      return hospital['name'].toString().toLowerCase().contains(query) ||
          hospital['address'].toString().toLowerCase().contains(query) ||
          (hospital['specialties'] as List<String>).any((s) => s.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Animate(
                effects: [
                  FadeEffect(duration: 300.ms),
                  SlideEffect(
                    begin: const Offset(-0.2, 0),
                    end: const Offset(0, 0),
                    duration: 300.ms,
                  ),
                ],
                child: Text(
                  'Nearby Hospitals',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Animate(
                effects: [
                  FadeEffect(duration: 300.ms, delay: 200.ms),
                  SlideEffect(
                    begin: const Offset(-0.2, 0),
                    end: const Offset(0, 0),
                    duration: 300.ms,
                    delay: 200.ms,
                  ),
                ],
                child: Text(
                  'Find medical facilities near you',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Animate(
                effects: const [
                  FadeEffect(duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 400)),
                ],
                child: StyledCard(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search hospitals, specialties...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Hospital list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0).copyWith(top: 0),
            itemCount: _filteredHospitals.length,
            itemBuilder: (context, index) {
              final hospital = _filteredHospitals[index];
              return Animate(
                effects: [
                  FadeEffect(
                    duration: 300.ms,
                    delay: Duration(milliseconds: 600 + (index * 100)),
                  ),
                  SlideEffect(
                    begin: const Offset(0, 0.2),
                    end: const Offset(0, 0),
                    duration: 300.ms,
                    delay: Duration(milliseconds: 600 + (index * 100)),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: StyledCard(
                    onTap: () {
                      // TODO: Navigate to hospital details
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hospital details coming soon')),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hospital['name'] as String,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hospital['address'] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  hospital['distance'] as String,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hospital['rating'].toString(),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (hospital['emergency'] as bool)
                              Chip(
                                label: const Text('24/7 Emergency'),
                                avatar: const Icon(
                                  Icons.emergency_rounded,
                                  size: 16,
                                ),
                                backgroundColor: theme.colorScheme.errorContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ...(hospital['specialties'] as List).map((specialty) => Chip(
                              label: Text(specialty as String),
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 