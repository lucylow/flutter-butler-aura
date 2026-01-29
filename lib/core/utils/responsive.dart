import 'package:flutter/material.dart';

/// Responsive breakpoints for mobile, tablet, and desktop
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Extension to get responsive values based on screen size
extension ResponsiveExtension on BuildContext {
  /// Returns true if the screen width is mobile size
  bool get isMobile => MediaQuery.of(this).size.width < Breakpoints.mobile;
  
  /// Returns true if the screen width is tablet size
  bool get isTablet => 
      MediaQuery.of(this).size.width >= Breakpoints.mobile && 
      MediaQuery.of(this).size.width < Breakpoints.desktop;
  
  /// Returns true if the screen width is desktop size
  bool get isDesktop => MediaQuery.of(this).size.width >= Breakpoints.desktop;
  
  /// Returns the screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Returns the screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Returns padding based on screen size
  EdgeInsets get responsivePadding {
    if (isMobile) {
      return const EdgeInsets.all(16);
    } else if (isTablet) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }
  
  /// Returns horizontal padding based on screen size
  EdgeInsets get responsiveHorizontalPadding {
    if (isMobile) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }
  
  /// Returns the number of columns for grid layouts
  int get gridColumns {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }
  
  /// Returns the max width for content containers
  double get maxContentWidth {
    if (isMobile) return double.infinity;
    if (isTablet) return 800;
    return 1200;
  }
}

/// Widget builder that provides responsive values
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    
    return builder(context, isMobile, isTablet, isDesktop);
  }
}
