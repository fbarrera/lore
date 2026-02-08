import 'package:flutter/material.dart';

/// Responsive breakpoints and layout utilities for multi-device support.
enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Determine device type from screen width.
  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Whether the device is in landscape orientation.
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Get a value based on device type.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Content padding that adapts to screen size.
  static EdgeInsets contentPadding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      desktop: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
    );
  }

  /// Maximum content width for readability.
  static double maxContentWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 720.0,
      desktop: 960.0,
    );
  }

  /// Chat bubble max width as fraction of screen.
  static double chatBubbleMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return value(
      context,
      mobile: screenWidth * 0.85,
      tablet: screenWidth * 0.65,
      desktop: 600.0,
    );
  }

  /// Grid cross-axis count based on device.
  static int gridColumns(BuildContext context) {
    return value(context, mobile: 2, tablet: 3, desktop: 4);
  }

  /// Font scale factor respecting user accessibility settings.
  static double fontScale(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0);
  }
}

/// A widget that builds different layouts based on device type.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    switch (Responsive.deviceType(context)) {
      case DeviceType.desktop:
        return (desktop ?? tablet ?? mobile)(context);
      case DeviceType.tablet:
        return (tablet ?? mobile)(context);
      case DeviceType.mobile:
        return mobile(context);
    }
  }
}

/// Constrains child to a maximum width, centered.
class ContentConstraint extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ContentConstraint({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
