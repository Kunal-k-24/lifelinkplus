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
      final user = userCredential.user!;

      if (mounted) {
        final hasProfile = await _authService.isUserProfileComplete();
        if (!hasProfile) {
          context.go('/profile-setup', extra: {
            'email': user.email!,
            'displayName': user.displayName ?? '',
            'photoUrl': user.photoURL,
          });
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
      body: ResponsiveLayout.safeArea(
        context: context,
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveLayout.withResponsivePadding(
              context: context,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: contentWidth,
                  minHeight: ResponsiveLayout.screenHeight(context) -
                      ResponsiveLayout.screenPadding(context).vertical -
                      verticalPadding * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Animate(
                      effects: [
                        FadeEffect(duration: 300.ms),
                        ScaleEffect(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 300.ms,
                        ),
                      ],
                      child: Icon(
                        Icons.favorite_rounded,
                        size: isSmallScreen ? 64 : 96,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Name
                    Animate(
                      effects: [
                        FadeEffect(duration: 300.ms, delay: 200.ms),
                        SlideEffect(
                          begin: const Offset(0, 0.2),
                          end: const Offset(0, 0),
                          duration: 300.ms,
                          delay: 200.ms,
                        ),
                      ],
                      child: Text(
                        'LifeLink+',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Animate(
                      effects: [
                        FadeEffect(duration: 300.ms, delay: 400.ms),
                        SlideEffect(
                          begin: const Offset(0, 0.2),
                          end: const Offset(0, 0),
                          duration: 300.ms,
                          delay: 400.ms,
                        ),
                      ],
                      child: Text(
                        'Your Modern Healthcare Companion',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 48 : 64),

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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen ? double.infinity : 600,
                        ),
                        child: Column(
                          children: [
                            _FeatureItem(
                              icon: Icons.medical_information_rounded,
                              title: 'Digital Health Card',
                              description: 'Keep your medical information handy',
                            ),
                            const SizedBox(height: 16),
                            _FeatureItem(
                              icon: Icons.local_hospital_rounded,
                              title: 'Find Hospitals',
                              description: 'Locate nearby healthcare facilities',
                            ),
                            const SizedBox(height: 16),
                            _FeatureItem(
                              icon: Icons.health_and_safety_rounded,
                              title: 'First Aid Guide',
                              description: 'Quick access to emergency procedures',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 48 : 64),

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
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: isSmallScreen ? 24 : 28,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
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