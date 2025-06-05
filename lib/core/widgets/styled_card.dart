import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StyledCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool elevated;
  final bool animate;

  const StyledCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding,
    this.elevated = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    Widget card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: padding ?? EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          decoration: BoxDecoration(
            color: color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: elevated ? [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: child,
        ),
      ),
    );

    if (animate) {
      card = card.animate().fadeIn(
        duration: 600.ms,
        curve: Curves.easeOut,
      ).slideY(
        begin: 0.1,
        end: 0,
        duration: 600.ms,
        curve: Curves.easeOut,
      );
    }

    return card;
  }
} 