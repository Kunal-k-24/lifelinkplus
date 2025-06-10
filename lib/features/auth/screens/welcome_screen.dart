import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_layout.dart';
import '../services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential.user;

      if (user == null) {
        throw 'Failed to sign in with Google';
      }

      if (!mounted) return;

      // Check if user has a complete profile
        final hasProfile = await _authService.isUserProfileComplete();
      
      if (!mounted) return;

        if (!hasProfile) {
        // Navigate to profile setup if profile is incomplete
          context.go('/profile-setup', extra: {
          'email': user.email ?? '',
            'displayName': user.displayName ?? '',
            'photoUrl': user.photoURL,
          });
        } else {
        // Navigate to home if profile is complete
          context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = ResponsiveLayout.isMobile(context);
    final contentWidth = ResponsiveLayout.contentMaxWidth(context);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final verticalPadding = ResponsiveLayout.verticalPadding(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  // App Logo and Title
                    Animate(
                      effects: [
                        FadeEffect(duration: 300.ms),
                      SlideEffect(
                        begin: const Offset(0, -0.2),
                        end: const Offset(0, 0),
                          duration: 300.ms,
                        ),
                      ],
                      child: Icon(
                        Icons.favorite_rounded,
                        size: isSmallScreen ? 64 : 96,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 16),
                    Animate(
                      effects: [
                        FadeEffect(duration: 300.ms, delay: 200.ms),
                        SlideEffect(
                        begin: const Offset(0, -0.2),
                          end: const Offset(0, 0),
                          duration: 300.ms,
                          delay: 200.ms,
                        ),
                      ],
                      child: Text(
                      'LifeLink Plus',
                      style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Animate(
                      effects: [
                        FadeEffect(duration: 300.ms, delay: 400.ms),
                        SlideEffect(
                        begin: const Offset(0, -0.2),
                          end: const Offset(0, 0),
                          duration: 300.ms,
                          delay: 400.ms,
                        ),
                      ],
                      child: Text(
                      'Your Personal Health Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 48),

                    // Features List
                    Animate(
                      effects: [
                        FadeEffect(duration: 300.ms, delay: 600.ms),
                        SlideEffect(
                          begin: const Offset(0, 0.2),
                          end: const Offset(0, 0),
                          duration: 300.ms,
                          delay: 600.ms,
                        ),
                      ],
                        child: Column(
                          children: [
                            _FeatureItem(
                          icon: Icons.local_hospital_rounded,
                          title: 'Find Nearby Hospitals',
                          description: 'Quickly locate medical facilities in your area',
                            ),
                            const SizedBox(height: 16),
                            _FeatureItem(
                          icon: Icons.medical_services_rounded,
                          title: 'First Aid Guide',
                          description: 'Step-by-step emergency medical assistance',
                            ),
                            const SizedBox(height: 16),
                            _FeatureItem(
                          icon: Icons.badge_rounded,
                          title: 'Digital Health Card',
                          description: 'Keep your medical information accessible',
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 48),

                    // Sign In Button
                    Animate(
                      effects: [
                        FadeEffect(duration: 300.ms, delay: 800.ms),
                        SlideEffect(
                          begin: const Offset(0, 0.2),
                          end: const Offset(0, 0),
                          duration: 300.ms,
                          delay: 800.ms,
                        ),
                      ],
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen ? double.infinity : 400,
                        ),
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: _isLoading
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            _isLoading ? 'Signing in...' : 'Continue with Google',
                          ),
                        ),
                      ),
                    ),
                  ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isSmallScreen) const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 