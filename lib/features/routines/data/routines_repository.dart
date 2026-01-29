import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine.dart';

final routinesRepositoryProvider = Provider<RoutinesRepository>((ref) {
  return RoutinesRepository();
});

/// In-memory list of routines. Can be replaced with API/local DB later.
class RoutinesRepository {
  static final List<Routine> _defaultRoutines = [
    const Routine(
      id: 'lock_doors',
      name: 'Lock all doors',
      description: 'Secures all smart locks',
      iconName: 'lock',
    ),
    const Routine(
      id: 'dim_lights',
      name: 'Dim lights to 10%',
      description: 'Sets living room and bedroom lights to 10%',
      iconName: 'lightbulb',
    ),
    const Routine(
      id: 'thermostat_night',
      name: 'Set thermostat to 68°F',
      description: 'Comfortable sleeping temperature',
      iconName: 'thermometer',
    ),
    const Routine(
      id: 'goodnight',
      name: 'Goodnight scene',
      description: 'Locks doors, dims lights, sets thermostat',
      iconName: 'moon',
    ),
    const Routine(
      id: 'leave_home',
      name: 'Leave home',
      description: 'Turns off lights, arms security, adjusts thermostat',
      iconName: 'home',
    ),
  ];

  List<Routine> getRoutines() => List.unmodifiable(_defaultRoutines);

  /// Run a routine by id. Calls Serverpod when configured; otherwise demo delay.
  Future<void> runRoutine(String id) async {
    if (serverpodAuraApi != null && serverpodAuraApi!.isConfigured) {
      try {
        await serverpodAuraApi!.runRoutine(id);
        debugPrint('✅ Routine $id run via Serverpod');
        return;
      } catch (e) {
        debugPrint('⚠️ Serverpod routine failed, using demo: $e');
        // Fall through to demo delay
      }
    }
    await Future.delayed(const Duration(milliseconds: 400));
  }
}

final routinesListProvider = Provider<List<Routine>>((ref) {
  final repo = ref.watch(routinesRepositoryProvider);
  return repo.getRoutines();
});
