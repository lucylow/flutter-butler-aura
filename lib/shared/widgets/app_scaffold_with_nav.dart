import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/aura_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/haptic_feedback.dart';
import 'aura_logo.dart';
import 'bottom_nav_bar.dart';

/// App shell: NavigationRail on web/Chrome (wide), BottomNavBar on mobile.
/// Use for Dashboard, Devices, and Chat so Chrome feels like a web dashboard.
class AppScaffoldWithNav extends StatelessWidget {
  const AppScaffoldWithNav({
    super.key,
    required this.currentPath,
    required this.appBar,
    required this.body,
  });

  final String currentPath;
  final PreferredSizeWidget appBar;
  final Widget body;

  bool _useRail(BuildContext context) {
    return kIsWeb && !context.isMobile;
  }

  int _selectedIndex(String path) {
    if (path == '/') return 0;
    if (path.startsWith('/devices')) return 1;
    if (path.startsWith('/chat')) return 2;
    return 0;
  }

  void _onRailTap(BuildContext context, int index) {
    HapticUtils.selectionClick();
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/devices');
        break;
      case 2:
        context.go('/chat');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final useRail = _useRail(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final railBg = isDark ? AuraColors.darkSlateBg : AuraColors.surfaceLight;
    final selectedIndex = _selectedIndex(currentPath);

    if (useRail) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: appBar,
        body: Row(
          children: [
            Container(
              width: 72,
              decoration: BoxDecoration(
                color: railBg,
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIndex: selectedIndex,
                onDestinationSelected: (i) => _onRailTap(context, i),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: AuraLogo(
                    size: 36,
                    onLightBackground: !isDark,
                  ),
                ),
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: IconThemeData(color: AuraColors.teal, size: 24),
                unselectedIconTheme: IconThemeData(
                  color: isDark ? AuraColors.textOnDark.withValues(alpha: 0.7) : AuraColors.textLight,
                  size: 22,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.layoutDashboard),
                    selectedIcon: Icon(LucideIcons.layoutDashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.lightbulb),
                    selectedIcon: Icon(LucideIcons.lightbulb),
                    label: Text('Devices'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.messageCircle),
                    selectedIcon: Icon(LucideIcons.messageCircle),
                    label: Text('Goals'),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
