import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/theme_mode_provider.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/routines/data/routines_repository.dart';
import '../../shared/widgets/app_scaffold_with_nav.dart';
import '../../shared/widgets/aura_app_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;
    final maxW = context.maxContentWidth;

    return AppScaffoldWithNav(
      currentPath: GoRouterState.of(context).matchedLocation,
      appBar: AuraAppBar(
        onThemeTap: () => ref.read(themeModeProvider.notifier).toggleLightDark(),
        onSignOut: () => ref.read(authStateProvider.notifier).signOut(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticUtils.lightImpact();
          await Future.delayed(const Duration(milliseconds: 400));
        },
        color: AuraColors.teal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            0,
            isMobile ? 16 : 24,
            isMobile ? 88 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildMainCard(context, ref, isMobile),
                  const SizedBox(height: 24),
                  _buildFooterStats(context),
                  const SizedBox(height: 20),
                  _buildTuyaCredit(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, WidgetRef ref, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AuraColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalInputRow(context, ref),
          const SizedBox(height: 20),
          _buildQuickGoalChips(context, ref),
          const SizedBox(height: 24),
          _buildCentralAuraCircle(context),
          const SizedBox(height: 20),
          _buildGoalBlurb(context),
          const SizedBox(height: 24),
          _buildSpecialistAgentsSection(context),
          const SizedBox(height: 24),
          _buildDeviceGrid(context),
          const SizedBox(height: 20),
          _buildSectionLabel(context, 'Routines'),
          const SizedBox(height: 10),
          _buildRoutineItem(context, ref, 'goodnight', 'Goodnight scene — lock doors, dim lights, set thermostat'),
          const SizedBox(height: 10),
          _buildRoutineItem(context, ref, 'leave_home', 'Leave home — lights off, security armed, thermostat adjusted'),
          const SizedBox(height: 10),
          _buildRoutineItem(context, ref, 'lock_doors', 'Lock all doors'),
          const SizedBox(height: 10),
          _buildRoutineItem(context, ref, 'dim_lights', 'Dim lights to 10%'),
          const SizedBox(height: 10),
          _buildRoutineItem(context, ref, 'thermostat_night', 'Set thermostat to 68°F'),
        ],
      ),
    );
  }

  Widget _buildGoalBlurb(BuildContext context) {
    return Center(
      child: Text(
        'Goal-oriented orchestration — say what you want, A.U.R.A. plans and executes.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: AuraColors.textOnDark.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AuraColors.textOnDark.withValues(alpha: 0.9),
        letterSpacing: 0.3,
      ),
    );
  }

  static const List<Map<String, dynamic>> _specialists = [
    {'name': 'Security', 'desc': 'Locks, alarms', 'icon': LucideIcons.lock},
    {'name': 'Ambiance', 'desc': 'Lights, climate, audio', 'icon': LucideIcons.palette},
    {'name': 'Energy', 'desc': 'Plugs, consumption', 'icon': LucideIcons.zap},
    {'name': 'Wellness', 'desc': 'Air quality, routines', 'icon': LucideIcons.heart},
  ];

  Widget _buildSpecialistAgentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, 'Specialist Agents'),
        const SizedBox(height: 12),
        Row(
          children: _specialists.map((s) {
            return Expanded(
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AuraColors.surfaceLight.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AuraColors.teal.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(s['icon'] as IconData, size: 22, color: AuraColors.teal),
                      const SizedBox(height: 6),
                      Text(
                        s['name'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AuraColors.textOnDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        s['desc'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          color: AuraColors.textOnDark.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGoalInputRow(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AuraColors.teal.withValues(alpha: 0.4),
          child: const Icon(LucideIcons.target, color: AuraColors.textOnTeal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AuraColors.textDark.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AuraColors.teal.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: GestureDetector(
              onTap: () {
                HapticUtils.lightImpact();
                context.push('/chat');
              },
              child: Row(
                children: [
                  Icon(LucideIcons.messageCircle, size: 18, color: AuraColors.textOnDark.withValues(alpha: 0.8)),
                  const SizedBox(width: 10),
                  Text(
                    'Tell A.U.R.A. what you want...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AuraColors.textOnDark.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const List<Map<String, dynamic>> _quickGoals = [
    {'name': 'Goodnight', 'goal': 'Goodnight, A.U.R.A. Lock doors, dim lights, set thermostat.', 'icon': LucideIcons.moon},
    {'name': 'Movie Time', 'goal': 'Set up for movie night.', 'icon': LucideIcons.film},
    {'name': 'Away Mode', 'goal': 'I\'m leaving home. Arm security and turn off lights.', 'icon': LucideIcons.car},
    {'name': 'Wake Up', 'goal': 'Wake up routine. Turn on lights and set thermostat.', 'icon': LucideIcons.sun},
  ];

  Widget _buildQuickGoalChips(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickGoals.map((goal) {
        return ActionChip(
          avatar: Icon(goal['icon'] as IconData, size: 16, color: AuraColors.teal),
          label: Text(
            goal['name'] as String,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AuraColors.surfaceLight.withValues(alpha: 0.6),
          side: BorderSide(color: AuraColors.teal.withValues(alpha: 0.5)),
          onPressed: () {
            HapticUtils.lightImpact();
            ref.read(chatProvider.notifier).sendMessage(goal['goal'] as String);
            context.push('/chat');
          },
        );
      }).toList(),
    );
  }

  Widget _buildCentralAuraCircle(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AuraColors.teal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AuraColors.teal.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(LucideIcons.bot, size: 48, color: AuraColors.textOnTeal),
          ),
          const SizedBox(height: 6),
          const Text(
            'A.U.R.A.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AuraColors.textOnDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Your Flutter Butler',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AuraColors.textOnDark.withValues(alpha: 0.75),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _deviceTiles = [
    {'icon': LucideIcons.lightbulb, 'label': 'Lights', 'specialist': 'Ambiance'},
    {'icon': LucideIcons.thermometer, 'label': 'Climate', 'specialist': 'Ambiance'},
    {'icon': LucideIcons.lock, 'label': 'Locks', 'specialist': 'Security'},
    {'icon': LucideIcons.plug, 'label': 'Plugs', 'specialist': 'Energy'},
  ];

  Widget _buildDeviceGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, 'Devices by type'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          children: _deviceTiles.map((t) {
            return _buildDeviceTile(
              context,
              t['icon'] as IconData,
              t['label'] as String,
              t['specialist'] as String,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeviceTile(BuildContext context, IconData icon, String label, String specialist) {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        context.push('/devices');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AuraColors.successCheck,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: AuraColors.textDark),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AuraColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialist,
                  style: TextStyle(
                    fontSize: 10,
                    color: AuraColors.textDark.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineItem(BuildContext context, WidgetRef ref, String routineId, String text) {
    final theme = Theme.of(context);
    final cardColor = theme.brightness == Brightness.dark
        ? AuraColors.surfaceDark.withValues(alpha: 0.5)
        : AuraColors.lightGreyCard.withValues(alpha: 0.8);
    final textColor = theme.textTheme.bodyLarge?.color ?? AuraColors.textDark;

    return GestureDetector(
      onTap: () async {
        HapticUtils.lightImpact();
        try {
          await ref.read(routinesRepositoryProvider).runRoutine(routineId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.check, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Ran: $text')),
                  ],
                ),
                backgroundColor: AuraColors.successCheck,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AuraColors.successCheck,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const Icon(LucideIcons.play, size: 16, color: AuraColors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text(
                '5',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AuraColors.teal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Specialized AI Agents',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AuraColors.textDark.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                '50+',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AuraColors.teal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Device Types Supported',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AuraColors.textDark.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                '<100ms',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AuraColors.teal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Average Response Time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AuraColors.textDark.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTuyaCredit(BuildContext context) {
    return Center(
      child: Text(
        'Built on Tuya Open Platform • Goal-oriented orchestration',
        style: TextStyle(
          fontSize: 11,
          color: AuraColors.textDark.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
