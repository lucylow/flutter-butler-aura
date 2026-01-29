import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/env.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            HapticUtils.lightImpact();
            context.pop();
          },
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color ?? AuraColors.textDark,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          8,
          isMobile ? 16 : 24,
          isMobile ? 88 : 24,
        ),
        children: [
          const _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            icon: LucideIcons.palette,
            title: 'Theme',
            subtitle: _themeModeLabel(themeMode),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              isDense: true,
              underline: const SizedBox(),
              icon: Icon(LucideIcons.chevronDown, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              ],
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  HapticUtils.selectionClick();
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Assistant'),
          _SettingsTile(
            icon: LucideIcons.key,
            title: 'AI API Keys',
            subtitle: 'Configure OpenAI, Anthropic, or Gemini keys for chat',
            onTap: () {
              HapticUtils.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Set OPENAI_API_KEY, ANTHROPIC_API_KEY, or GEMINI_API_KEY in your environment.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'About'),
          const _SettingsTile(
            icon: LucideIcons.info,
            title: 'A.U.R.A.',
            subtitle: 'Autonomous & Unified Residential Administrator • Cloud-Based Smart Home AI Executive • v0.1.0',
          ),
          if (Env.isAuraBackendConfigured())
            const _SettingsTile(
              icon: LucideIcons.server,
              title: 'A.U.R.A. Backend',
              subtitle: 'Goal API connected (AURA_BACKEND_URL)',
            ),
          if (Env.isGoalBackendConfigured() && !Env.isAuraBackendConfigured())
            const _SettingsTile(
              icon: LucideIcons.server,
              title: 'Serverpod Aura API',
              subtitle: 'Goal API via Serverpod (see SERVERPOD_AURA_API.md)',
            ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Links'),
          _SettingsTile(
            icon: LucideIcons.globe,
            title: 'Lovable app (reference)',
            subtitle: 'tuya-aura.lovable.app',
            onTap: () => _openUrl('https://tuya-aura.lovable.app'),
          ),
          _SettingsTile(
            icon: LucideIcons.github,
            title: 'GitHub — aura-smart-home-agent',
            subtitle: 'github.com/lucylow/aura-smart-home-agent',
            onTap: () => _openUrl('https://github.com/lucylow/aura-smart-home-agent'),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar() : null,
    );
  }

  Future<void> _openUrl(String url) async {
    HapticUtils.lightImpact();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Follow system';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: (Theme.of(context).textTheme.bodySmall?.color ?? AuraColors.textLight).withValues(alpha: 0.9),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? AuraColors.surfaceLight;
    final textColor = theme.textTheme.titleMedium?.color ?? AuraColors.textDark;
    final subColor = theme.textTheme.bodySmall?.color ?? AuraColors.textLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black26,
        elevation: theme.brightness == Brightness.dark ? 0 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AuraColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: AuraColors.teal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ] else if (onTap != null)
                  Icon(LucideIcons.chevronRight, size: 20, color: subColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
