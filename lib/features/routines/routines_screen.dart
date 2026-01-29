import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/aura_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'data/routines_repository.dart';
import 'models/routine.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesListProvider);
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
          'Routines',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color ?? AuraColors.textDark,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          16,
          isMobile ? 16 : 24,
          isMobile ? 88 : 24,
        ),
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];
          return _RoutineTile(
            routine: routine,
            onRun: () => _runRoutine(context, ref, routine),
          );
        },
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar() : null,
    );
  }

  Future<void> _runRoutine(BuildContext context, WidgetRef ref, Routine routine) async {
    HapticUtils.lightImpact();
    try {
      await ref.read(routinesRepositoryProvider).runRoutine(routine.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Ran: ${routine.name}')),
              ],
            ),
            backgroundColor: AuraColors.successCheck,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to run routine: $e'),
            backgroundColor: AuraColors.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

class _RoutineTile extends ConsumerWidget {
  final Routine routine;
  final VoidCallback onRun;

  const _RoutineTile({required this.routine, required this.onRun});

  IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'lock':
        return LucideIcons.lock;
      case 'lightbulb':
        return LucideIcons.lightbulb;
      case 'thermometer':
        return LucideIcons.thermometer;
      case 'moon':
        return LucideIcons.moon;
      case 'home':
        return LucideIcons.home;
      default:
        return LucideIcons.zap;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? AuraColors.surfaceLight;
    final textColor = theme.textTheme.titleMedium?.color ?? AuraColors.textDark;
    final subColor = theme.textTheme.bodySmall?.color ?? AuraColors.textLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AuraColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(routine.iconName), color: AuraColors.teal, size: 22),
          ),
          title: Text(
            routine.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textColor,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              routine.description,
              style: TextStyle(fontSize: 12, color: subColor),
            ),
          ),
          trailing: FilledButton.icon(
            onPressed: onRun,
            icon: const Icon(LucideIcons.play, size: 16),
            label: const Text('Run'),
            style: FilledButton.styleFrom(
              backgroundColor: AuraColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
          ),
        ),
      ),
    );
  }
}
