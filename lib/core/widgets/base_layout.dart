import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../utils/responsive_layout.dart';
import 'bottom_nav_bar.dart';
import '../../features/sos/services/sos_service.dart';

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

class _SOSButton extends StatefulWidget {
  @override
  State<_SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<_SOSButton> {
  final _sosService = SOSService();
  bool _isActive = false;

  @override
  void dispose() {
    _sosService.dispose();
    super.dispose();
  }

  Future<void> _handleSOS() async {
    setState(() => _isActive = !_isActive);

    if (_isActive) {
      // Start SOS sequence
      await _sosService.playAlarm();

      if (!mounted) return;
      
      // Show demo SMS dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              const Text('Emergency Alert'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demo SMS Content:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_sosService.getDemoSMSText()),
              const SizedBox(height: 16),
              const Text(
                'In a real emergency:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• SMS would be sent to emergency contacts'),
              const Text('• Location would be shared'),
              const Text('• Medical info would be included'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sosService.callEmergency();
              },
              child: const Text('Call Emergency (108)'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isActive = false);
                _sosService.stopAlarm();
              },
              child: const Text('Stop Alert'),
            ),
          ],
        ),
      );
    } else {
      await _sosService.stopAlarm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = ResponsiveLayout.isMobile(context);
    final buttonSize = isSmallScreen ? 56.0 : 64.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleSOS,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isActive 
              ? theme.colorScheme.error 
              : theme.colorScheme.error.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withOpacity(_isActive ? 0.4 : 0.2),
                blurRadius: _isActive ? 16 : 12,
                spreadRadius: _isActive ? 4 : 2,
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
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: 2.seconds,
      delay: 1.seconds,
    ).scale(
      duration: 500.ms,
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      curve: Curves.easeInOut,
    ).then(delay: 500.ms).scale(
      duration: 500.ms,
      begin: const Offset(1.05, 1.05),
      end: const Offset(1, 1),
      curve: Curves.easeInOut,
    );
  }
} 