import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/styled_card.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_profile.dart';

class HealthCardScreen extends StatefulWidget {
  const HealthCardScreen({super.key});

  @override
  State<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen> {
  final _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile(_authService.currentUser!.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfile == null) {
      return const Center(child: Text('Profile not found'));
    }

    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return SingleChildScrollView(
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
              'Emergency Health Card',
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
              'Keep this information handy in case of emergency',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Main Health Card
          Animate(
            effects: [
              FadeEffect(duration: 300.ms, delay: 400.ms),
              ScaleEffect(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 300.ms,
                delay: 400.ms,
              ),
            ],
            child: StyledCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'profile_photo',
                        child: CircleAvatar(
                          radius: isSmallScreen ? 30 : 40,
                          backgroundImage: _userProfile!.photoUrl != null
                              ? NetworkImage(_userProfile!.photoUrl!)
                              : null,
                          child: _userProfile!.photoUrl == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: isSmallScreen ? 30 : 40,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile!.fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Age: ${_userProfile!.age} • ${_userProfile!.gender}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    title: 'Blood Type',
                    value: _userProfile!.bloodGroup,
                    icon: Icons.bloodtype_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    title: 'Height',
                    value: '${_userProfile!.height} cm',
                    icon: Icons.height_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    title: 'Weight',
                    value: '${_userProfile!.weight} kg',
                    icon: Icons.monitor_weight_rounded,
                    theme: theme,
                  ),
                  if (_userProfile!.allergies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      title: 'Allergies',
                      value: _userProfile!.allergies.join(', '),
                      icon: Icons.warning_rounded,
                      theme: theme,
                      isWarning: true,
                    ),
                  ],
                  if (_userProfile!.medicalConditions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      title: 'Medical Conditions',
                      value: _userProfile!.medicalConditions.join(', '),
                      icon: Icons.medical_information_rounded,
                      theme: theme,
                      isWarning: true,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Emergency Contacts Card
          Animate(
            effects: [
              FadeEffect(duration: 300.ms, delay: 600.ms),
              ScaleEffect(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 300.ms,
                delay: 600.ms,
              ),
            ],
            child: StyledCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Contacts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactTile(
                    name: 'Emergency Services',
                    number: '911',
                    icon: Icons.emergency_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildContactTile(
                    name: 'Local Hospital',
                    number: '+1 (555) 123-4567',
                    icon: Icons.local_hospital_rounded,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String value,
    required IconData icon,
    required ThemeData theme,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isWarning
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isWarning
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                  fontWeight: isWarning ? FontWeight.w500 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required String name,
    required String number,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                number,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone_rounded),
          onPressed: () {
            // TODO: Implement phone call functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Calling feature coming soon')),
            );
          },
          tooltip: 'Call $name',
        ),
      ],
    );
  }
} 