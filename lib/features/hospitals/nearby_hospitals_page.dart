import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/base_layout.dart';

class NearbyHospitalsPage extends StatelessWidget {
  const NearbyHospitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 1,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Nearby Hospitals'),
              centerTitle: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                  _buildHospitalsList(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search hospitals...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildHospitalsList(BuildContext context) {
    return Column(
      children: [
        _HospitalCard(
          name: 'City General Hospital',
          distance: '1.2 km',
          rating: 4.5,
          address: '123 Medical Center Dr.',
          phone: '+1 (555) 123-4567',
          isOpen: true,
        ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 100)),
        const SizedBox(height: 12),
        _HospitalCard(
          name: 'St. Mary\'s Medical Center',
          distance: '2.8 km',
          rating: 4.8,
          address: '456 Healthcare Ave.',
          phone: '+1 (555) 987-6543',
          isOpen: true,
        ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 200)),
        const SizedBox(height: 12),
        _HospitalCard(
          name: 'Community Care Hospital',
          distance: '3.5 km',
          rating: 4.2,
          address: '789 Wellness Blvd.',
          phone: '+1 (555) 246-8135',
          isOpen: false,
        ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 300)),
      ],
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final String name;
  final String distance;
  final double rating;
  final String address;
  final String phone;
  final bool isOpen;

  const _HospitalCard({
    required this.name,
    required this.distance,
    required this.rating,
    required this.address,
    required this.phone,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(distance),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(rating.toString()),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: isOpen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    // TODO: Implement directions functionality
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 