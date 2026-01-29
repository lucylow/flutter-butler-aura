import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/aura_colors.dart';
import '../../core/utils/haptic_feedback.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location == '/devices') return 1;
    if (location == '/chat') return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
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
    final currentIndex = _getCurrentIndex(context);

    // Use Cupertino-style bottom nav only on iOS devices (not on web)
    final isCupertinoStyle = !kIsWeb && Theme.of(context).platform == TargetPlatform.iOS;

    if (isCupertinoStyle) {
      return Container(
        decoration: BoxDecoration(
          color: AuraColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: CupertinoTabBar(
          backgroundColor: AuraColors.surfaceLight,
          activeColor: AuraColors.teal,
          inactiveColor: AuraColors.textLight,
          currentIndex: currentIndex,
          onTap: (index) => _onTap(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.layoutDashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.lightbulb),
              label: 'Devices',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.messageCircle),
              label: 'Goals',
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AuraColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: AuraColors.surfaceLight,
        selectedItemColor: AuraColors.teal,
        unselectedItemColor: AuraColors.textLight,
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.lightbulb),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.messageCircle),
            label: 'Goals',
          ),
        ],
      ),
    );
  }
}
