import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'serverpod_client.dart';
import 'serverpod_service.dart';

/// Helper utilities for common Serverpod operations
class ServerpodHelpers {
  /// Execute a Serverpod operation with automatic retry and error handling
  /// 
  /// Example:
  /// ```dart
  /// final result = await ServerpodHelpers.executeWithRetry(
  ///   ref,
  ///   () => client.myEndpoint.doSomething(),
  ///   maxRetries: 3,
  /// );
  /// ```
  static Future<T?> executeWithRetry<T>(
    Ref ref,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool Function(Object)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // Check if client is available
        final client = ref.read(serverpodClientProvider);
        if (client == null) {
          throw Exception('Serverpod client not available');
        }

        // Check connection state
        final connectionState = ref.read(serverpodConnectionStateProvider);
        if (connectionState != ServerpodConnectionState.connected) {
          throw Exception('Serverpod not connected');
        }

        // Execute operation
        return await operation();
      } catch (e) {
        attempts++;
        
        // Check if we should retry
        if (shouldRetry != null && !shouldRetry(e)) {
          debugPrint('❌ Serverpod operation failed (no retry): $e');
          rethrow;
        }

        if (attempts >= maxRetries) {
          debugPrint('❌ Serverpod operation failed after $maxRetries attempts: $e');
          rethrow;
        }

        debugPrint('⚠️ Serverpod operation failed (attempt $attempts/$maxRetries): $e');
        debugPrint('🔄 Retrying in ${retryDelay.inSeconds} seconds...');

        // Try to reconnect if connection is lost
        final service = ref.read(serverpodServiceProvider);
        if (!service.isConnected) {
          await service.reconnect();
        }

        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Failed to execute Serverpod operation after $maxRetries attempts');
  }

  /// Execute a Serverpod operation with connection check
  /// Returns null if client is not available or not connected
  static Future<T?> executeIfConnected<T>(
    Ref ref,
    Future<T> Function() operation,
  ) async {
    try {
      final client = ref.read(serverpodClientProvider);
      if (client == null) {
        debugPrint('⚠️ Serverpod client not available');
        return null;
      }

      final connectionState = ref.read(serverpodConnectionStateProvider);
      if (connectionState != ServerpodConnectionState.connected) {
        debugPrint('⚠️ Serverpod not connected');
        return null;
      }

      return await operation();
    } catch (e) {
      debugPrint('❌ Serverpod operation failed: $e');
      return null;
    }
  }

  /// Check if Serverpod is ready to use
  static bool isReady(Ref ref) {
    final client = ref.read(serverpodClientProvider);
    if (client == null) return false;

    final connectionState = ref.read(serverpodConnectionStateProvider);
    return connectionState == ServerpodConnectionState.connected;
  }

  /// Get connection status message for UI
  static String getConnectionStatusMessage(Ref ref) {
    final connectionState = ref.read(serverpodConnectionStateProvider);
    
    switch (connectionState) {
      case ServerpodConnectionState.connected:
        return 'Connected';
      case ServerpodConnectionState.disconnected:
        return 'Disconnected';
      case ServerpodConnectionState.connecting:
        return 'Connecting...';
      case ServerpodConnectionState.error:
        final service = ref.read(serverpodServiceProvider);
        return 'Error: ${service.lastError ?? "Unknown error"}';
    }
  }

  /// Stream helper for Serverpod streaming endpoints
  /// Handles connection state and error recovery
  static Stream<T> streamWithRetry<T>(
    Ref ref,
    Stream<T> Function() streamFactory, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async* {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // Check connection before starting stream
        if (!isReady(ref)) {
          throw Exception('Serverpod not ready');
        }

        await for (final value in streamFactory()) {
          yield value;
          attempts = 0; // Reset attempts on successful stream
        }
        
        // Stream completed successfully
        return;
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          debugPrint('❌ Serverpod stream failed after $maxRetries attempts: $e');
          return;
        }

        debugPrint('⚠️ Serverpod stream error (attempt $attempts/$maxRetries): $e');
        debugPrint('🔄 Retrying stream in ${retryDelay.inSeconds} seconds...');

        // Try to reconnect
        final service = ref.read(serverpodServiceProvider);
        if (!service.isConnected) {
          await service.reconnect();
        }

        await Future.delayed(retryDelay);
      }
    }
  }
}
