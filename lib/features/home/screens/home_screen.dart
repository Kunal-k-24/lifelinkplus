import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/styled_card.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      if (_authService.currentUser == null) {
        if (mounted) {
          context.go('/welcome');
        }
        return;
      }

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

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          StyledCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'profile_photo',
                      child: CircleAvatar(
                        radius: isSmallScreen ? 30 : 40,
                        backgroundImage: _userProfile?.photoUrl != null
                            ? NetworkImage(_userProfile!.photoUrl!)
                            : null,
                        child: _userProfile?.photoUrl == null
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
                            'Welcome back,',
                            style: theme.textTheme.bodyLarge,
                          ),
                          Text(
                            _userProfile?.fullName ?? 'User',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _handleSignOut,
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Sign Out',
                    ),
                  ],
                ),
                if (_userProfile != null) ...[
                  const SizedBox(height: 24),
                  _HealthInfoTile(
                    icon: Icons.monitor_heart_rounded,
                    title: 'Blood Group',
                    value: _userProfile!.bloodGroup,
                  ),
                  const SizedBox(height: 16),
                  _HealthInfoTile(
                    icon: Icons.medical_information_rounded,
                    title: 'Medical Conditions',
                    value: _userProfile!.medicalConditions.join(', '),
                  ),
                  const SizedBox(height: 16),
                  _HealthInfoTile(
                    icon: Icons.warning_rounded,
                    title: 'Allergies',
                    value: _userProfile!.allergies.join(', '),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions Grid
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isSmallScreen ? 2 : 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _QuickActionCard(
                icon: Icons.local_hospital_rounded,
                title: 'Find Hospitals',
                subtitle: 'Locate nearby hospitals',
                onTap: () => context.go('/hospitals'),
              ),
              _QuickActionCard(
                icon: Icons.medical_information_rounded,
                title: 'First Aid Guide',
                subtitle: 'Quick medical assistance',
                onTap: () => context.go('/first-aid'),
              ),
              _QuickActionCard(
                icon: Icons.badge_rounded,
                title: 'Health Card',
                subtitle: 'View your health info',
                onTap: () => context.go('/health-card'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _HealthInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
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
                value.isEmpty ? 'None' : value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StyledCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 