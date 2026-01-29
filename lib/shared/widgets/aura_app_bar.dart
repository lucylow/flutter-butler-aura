import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/aura_colors.dart';
import 'aura_logo.dart';

/// A.U.R.A. app bar: logo, optional moon (theme), hamburger (menu with sign out).
class AuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuraAppBar({
    super.key,
    this.onMenuTap,
    this.onThemeTap,
    this.onSignOut,
    this.showThemeToggle = true,
    this.showMenuButton = true,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onThemeTap;
  /// When set, menu shows a "Sign out" option that calls this (Supabase auth).
  final VoidCallback? onSignOut;
  final bool showThemeToggle;
  final bool showMenuButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color ?? (isDark ? AuraColors.textOnDark : AuraColors.textDark);
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: AuraLogo(size: 32, onLightBackground: !isDark),
      ),
      titleSpacing: 0,
      actions: [
        if (showThemeToggle)
          IconButton(
            onPressed: onThemeTap,
            icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, color: iconColor),
          ),
        if (showMenuButton) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: onSignOut != null
                  ? () => _showMenu(context)
                  : onMenuTap,
              style: IconButton.styleFrom(
                backgroundColor: AuraColors.teal,
                foregroundColor: AuraColors.textOnTeal,
              ),
              icon: const Icon(LucideIcons.menu, size: 20),
            ),
          ),
        ],
      ],
    );
  }

  void _showMenu(BuildContext context) {
    final overlay = context.findRenderObject() as RenderBox?;
    final position = overlay?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = overlay?.size ?? Size.zero;
    final items = <PopupMenuEntry<String>>[];
    if (onMenuTap != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(LucideIcons.settings),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }
    if (onSignOut != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'signout',
          child: ListTile(
            leading: Icon(LucideIcons.logOut),
            title: Text('Sign out'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy + size.height + 48,
      ),
      items: items,
    ).then((String? value) {
      if (value == 'settings' && onMenuTap != null) onMenuTap!();
      if (value == 'signout' && onSignOut != null) onSignOut!();
    });
  }
}
