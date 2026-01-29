import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/device.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return DevicesRepository(Supabase.instance.client);
});

/// Stream of devices from Supabase; returns empty list when not authenticated.
final devicesListProvider = StreamProvider<List<Device>>((ref) {
  final isAuthenticated = ref.watch(authStateProvider).value != null;
  if (!isAuthenticated) return Stream.value(<Device>[]);
  final repository = ref.watch(devicesRepositoryProvider);
  return repository.getDevicesStream();
});

/// Repository for managing device data and operations
class DevicesRepository {
  final SupabaseClient _client;

  DevicesRepository(this._client);

  /// Get a stream of all devices
  /// 
  /// Returns a stream that emits updated device lists when changes occur
  Stream<List<Device>> getDevicesStream() {
    try {
      return _client
          .from('devices')
          .stream(primaryKey: ['id'])
          .map((data) {
            try {
              return data.map((json) => Device.fromJson(json)).toList();
            } catch (e) {
              debugPrint('❌ Error parsing device JSON: $e');
              return <Device>[];
            }
          })
          .handleError((error) {
            debugPrint('❌ Error in devices stream: $error');
            return <Device>[];
          });
    } catch (e) {
      debugPrint('❌ Failed to create devices stream: $e');
      return Stream.value(<Device>[]);
    }
  }

  /// Toggle a device on/off
  /// 
  /// [id] - The device ID
  /// [state] - The desired state (true = on, false = off)
  /// 
  /// Throws [Exception] if the update fails
  Future<void> toggleDevice(String id, bool state) async {
    if (id.isEmpty) {
      throw ArgumentError('Device ID cannot be empty');
    }

    try {
      // Fetch current device state to preserve other fields
      final currentDeviceResponse = await _client
          .from('devices')
          .select('current_state')
          .eq('id', id)
          .single();
      
      final currentState = currentDeviceResponse['current_state'] as Map<String, dynamic>? ?? {};
      
      // Merge new state with existing state to preserve other fields
      final updatedState = Map<String, dynamic>.from(currentState);
      updatedState['switch_1'] = state;
      updatedState['1'] = state; // Legacy Tuya index
      updatedState['power'] = state;
      updatedState['state'] = state;
      
      final updatePayload = {
        'current_state': updatedState,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('devices')
          .update(updatePayload)
          .eq('id', id)
          .select();
      
      if (response.isEmpty) {
        throw Exception('Device not found or update failed');
      }
      
      debugPrint('✅ Device $id toggled to ${state ? "on" : "off"}');
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error toggling device: ${e.message}');
      throw Exception('Failed to toggle device: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error toggling device: $e');
      rethrow;
    }
  }
  
  /// Get a single device by ID
  Future<Device?> getDevice(String id) async {
    try {
      final response = await _client
          .from('devices')
          .select()
          .eq('id', id)
          .single();
      
      return Device.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching device $id: $e');
      return null;
    }
  }
}
