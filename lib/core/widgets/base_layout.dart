import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../utils/responsive_layout.dart';
import 'bottom_nav_bar.dart';

class BaseLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const BaseLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final viewPadding = mediaQuery.viewPadding;
    final isSmallScreen = ResponsiveLayout.isMobile(context);

    return Scaffold(
      body: Stack(
        children: [
          // Main content with animation and safe area
          ResponsiveLayout.safeArea(
            context: context,
            child: widget.child.animate().fadeIn(
              duration: 300.ms,
              curve: Curves.easeOut,
            ).slideY(
              begin: 0.1,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOut,
            ),
          ),

          // SOS Button
          if (widget.currentIndex == 0) // Only show on home screen
            Positioned(
              right: ResponsiveLayout.horizontalPadding(context),
              bottom: isSmallScreen ? 80 : 96,
              child: _SOSButton(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/hospitals');
              break;
            case 2:
              context.go('/first-aid');
              break;
            case 3:
              context.go('/health-card');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}

class _SOSButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = ResponsiveLayout.isMobile(context);
    final buttonSize = isSmallScreen ? 56.0 : 64.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Implement SOS functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SOS Feature Coming Soon'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.error,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.emergency_rounded,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    )
    .animate(
      onPlay: (controller) => controller.repeat(),
    )
    .shimmer(
      duration: 2000.ms,
      color: Colors.white24,
    )
    .scale(
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      duration: 2000.ms,
      curve: Curves.easeInOut,
    )
    .then()
    .scale(
      begin: const Offset(1.05, 1.05),
      end: const Offset(1, 1),
      duration: 2000.ms,
      curve: Curves.easeInOut,
    );
  }
} 