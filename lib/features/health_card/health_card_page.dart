import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/base_layout.dart';

class HealthCardPage extends StatelessWidget {
  const HealthCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 3,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Emergency Health Card'),
              centerTitle: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHealthCard(context),
                  const SizedBox(height: 16),
                  _buildMedicalInfo(context),
                  const SizedBox(height: 16),
                  _buildEmergencyContacts(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Health Card',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const Icon(
                  Icons.medical_services,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'John Doe',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: 123-456-789',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CardInfo(
                  label: 'Blood Type',
                  value: 'A+',
                ),
                _CardInfo(
                  label: 'Age',
                  value: '32',
                ),
                _CardInfo(
                  label: 'Weight',
                  value: '75 kg',
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildMedicalInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoTile(
              icon: Icons.warning,
              title: 'Allergies',
              info: 'Penicillin, Peanuts',
            ),
            _InfoTile(
              icon: Icons.medical_information,
              title: 'Conditions',
              info: 'Asthma, Hypertension',
            ),
            _InfoTile(
              icon: Icons.medication,
              title: 'Medications',
              info: 'Ventolin, Lisinopril',
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 200));
  }

  Widget _buildEmergencyContacts(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contacts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _ContactTile(
              name: 'Jane Doe',
              relation: 'Spouse',
              phone: '+1 (555) 123-4567',
              onCall: () {},
            ),
            _ContactTile(
              name: 'Dr. Smith',
              relation: 'Primary Physician',
              phone: '+1 (555) 987-6543',
              onCall: () {},
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 400));
  }
}

class _CardInfo extends StatelessWidget {
  final String label;
  final String value;

  const _CardInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String info;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: Text(info),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String name;
  final String relation;
  final String phone;
  final VoidCallback onCall;

  const _ContactTile({
    required this.name,
    required this.relation,
    required this.phone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(relation),
      trailing: IconButton(
        icon: const Icon(Icons.phone),
        onPressed: onCall,
      ),
    );
  }
} 