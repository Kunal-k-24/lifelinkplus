import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelink/features/hospitals/screens/hospitals_screen.dart';

final router = GoRouter(
  initialLocation: '/hospitals',
  routes: [
    GoRoute(
      path: '/hospitals',
      builder: (context, state) => const HospitalsScreen(),
    ),
  ],
); 