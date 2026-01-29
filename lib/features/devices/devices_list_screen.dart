import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import 'repositories/devices_repository.dart';
import 'models/device.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../core/utils/responsive.dart';
import '../auth/providers/auth_provider.dart';
import '../../shared/widgets/app_scaffold_with_nav.dart';
import '../../shared/widgets/aura_app_bar.dart';

class DevicesListScreen extends ConsumerWidget {
  const DevicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesListProvider);
    final isMobile = context.isMobile;

    return AppScaffoldWithNav(
      currentPath: GoRouterState.of(context).matchedLocation,
      appBar: AuraAppBar(
        onMenuTap: () {
          HapticUtils.lightImpact();
          context.push('/settings');
        },
        onThemeTap: () {
          HapticUtils.selectionClick();
          ref.read(themeModeProvider.notifier).toggleLightDark();
        },
        onSignOut: () => ref.read(authStateProvider.notifier).signOut(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticUtils.lightImpact();
          ref.invalidate(devicesListProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AuraColors.teal,
        child: devicesAsync.when(
          data: (devices) {
            if (devices.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.smartphone,
                          size: 64,
                          color: AuraColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices yet',
                          style: TextStyle(
                            color: AuraColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Link Tuya devices via the Tuya Smart app, or add devices in your A.U.R.A. backend. Devices will appear here and can be controlled by goals (e.g. "Movie night", "I\'m cold").',
                          style: TextStyle(
                            color: AuraColors.textLight,
                            fontSize: 14,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final devicesByRoom = _groupDevicesByRoom(devices);

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                16,
                isMobile ? 16 : 24,
                isMobile ? 88 : 24,
              ),
              itemCount: devicesByRoom.length,
              itemBuilder: (context, index) {
                final room = devicesByRoom.keys.elementAt(index);
                final roomDevices = devicesByRoom[room]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        room,
                        style: const TextStyle(
                          color: AuraColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...roomDevices.map((device) => _DeviceTile(key: ValueKey(device.id), device: device)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AuraColors.teal),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    size: 64,
                    color: AuraColors.coral,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load devices',
                    style: TextStyle(
                      color: AuraColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: const TextStyle(
                      color: AuraColors.textLight,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(devicesListProvider),
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuraColors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<Device>> _groupDevicesByRoom(List<Device> devices) {
    final Map<String, List<Device>> grouped = {};
    for (var device in devices) {
      if (!grouped.containsKey(device.room)) {
        grouped[device.room] = [];
      }
      grouped[device.room]!.add(device);
    }
    return grouped;
  }
}

class _DeviceTile extends ConsumerWidget {
  final Device device;

  const _DeviceTile({super.key, required this.device});

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return LucideIcons.lightbulb;
      case 'switch':
        return LucideIcons.toggleLeft;
      case 'sensor':
        return LucideIcons.activity;
      case 'lock':
        return LucideIcons.lock;
      case 'thermostat':
        return LucideIcons.thermometer;
      default:
        return LucideIcons.box;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
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
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: device.isOn
                  ? AuraColors.teal.withValues(alpha: 0.15)
                  : AuraColors.lightGrey,
              shape: BoxShape.circle,
              border: Border.all(
                color: device.isOn
                    ? AuraColors.teal
                    : AuraColors.textLight.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              _getIconForType(device.type),
              color: device.isOn ? AuraColors.teal : AuraColors.textLight,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  device.name,
                  style: const TextStyle(
                    color: AuraColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!device.isOnline)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AuraColors.coral.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AuraColors.coral.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'Offline',
                    style: TextStyle(
                      color: AuraColors.coral,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: device.isOnline
                        ? AuraColors.successCheck
                        : AuraColors.textLight,
                    shape: BoxShape.circle,
                    boxShadow: device.isOnline
                        ? [
                            BoxShadow(
                              color: AuraColors.successCheck
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  device.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: device.isOnline
                        ? AuraColors.successCheck
                        : AuraColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          trailing: Switch(
            value: device.isOn,
            activeTrackColor: AuraColors.teal.withValues(alpha: 0.5),
            activeThumbColor: AuraColors.teal,
            onChanged: device.isOnline
                ? (val) async {
                    HapticUtils.selectionClick();
                    try {
                      await ref
                          .read(devicesRepositoryProvider)
                          .toggleDevice(device.id, val);
                    } catch (e) {
                      HapticUtils.vibrate();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(LucideIcons.alertCircle,
                                    color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('Failed to toggle device: $e'),
                                ),
                              ],
                            ),
                            backgroundColor: AuraColors.coral,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
