import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static EdgeInsets screenPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  static double horizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  static double verticalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  static double contentMaxWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width >= desktopBreakpoint) return 1200;
    if (width >= tabletBreakpoint) return 900;
    if (width >= mobileBreakpoint) return 600;
    return width;
  }

  static Widget withResponsivePadding({
    required BuildContext context,
    required Widget child,
    bool addHorizontal = true,
    bool addVertical = true,
    bool centerContent = true,
  }) {
    Widget content = child;

    if (addHorizontal || addVertical) {
      content = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: addHorizontal ? horizontalPadding(context) : 0,
          vertical: addVertical ? verticalPadding(context) : 0,
        ),
        child: content,
      );
    }

    if (centerContent && screenWidth(context) >= tabletBreakpoint) {
      content = Center(
        child: SizedBox(
          width: contentMaxWidth(context),
          child: content,
        ),
      );
    }

    return content;
  }

  static Widget safeArea({
    required BuildContext context,
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: EdgeInsets.symmetric(
        horizontal: horizontalPadding(context),
        vertical: verticalPadding(context),
      ),
      child: child,
    );
  }
} 