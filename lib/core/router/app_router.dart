import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/hospitals/screens/nearby_hospitals_screen.dart';
import '../../features/first_aid/screens/first_aid_screen.dart';
import '../../features/health_card/screens/health_card_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../widgets/base_layout.dart';

class AppRouter {
  AppRouter({required this.authService});

  final AuthService authService;

  late final router = GoRouter(
    refreshListenable: authService,
    redirect: _handleRedirect,
    routes: [
      // Auth routes
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ProfileSetupScreen(
            email: args['email'] as String,
            displayName: args['displayName'] as String,
            photoUrl: args['photoUrl'] as String?,
          );
        },
      ),

      // Main app routes
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.toString();
          int currentIndex;

          if (location.startsWith('/hospitals')) {
            currentIndex = 1;
          } else if (location.startsWith('/first-aid')) {
            currentIndex = 2;
          } else if (location.startsWith('/health-card')) {
            currentIndex = 3;
          } else if (location.startsWith('/settings')) {
            currentIndex = 4;
          } else {
            currentIndex = 0;
          }

          return BaseLayout(
            currentIndex: currentIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/hospitals',
            builder: (context, state) => const NearbyHospitalsScreen(),
          ),
          GoRoute(
            path: '/first-aid',
            builder: (context, state) => const FirstAidScreen(),
          ),
          GoRoute(
            path: '/health-card',
            builder: (context, state) => const HealthCardScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final user = authService.currentUser;
    final isOnWelcome = state.uri.toString() == '/welcome';
    final isOnProfileSetup = state.uri.toString() == '/profile-setup';

    if (user == null) {
      return isOnWelcome ? null : '/welcome';
    }

    if (isOnWelcome) {
      return '/';
    }

    return null;
  }
} 