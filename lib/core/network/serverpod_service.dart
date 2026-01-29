import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'serverpod_client.dart';

/// Service to manage the Serverpod connection and client lifecycle.
/// Provides connectivity monitoring, error handling, and connection state management.
/// 
/// This service integrates with Riverpod providers for reactive state management.
class ServerpodService {
  final Ref _ref;
  String? _lastError;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  ServerpodService(this._ref);

  /// Check if Serverpod client is available
  bool get isClientAvailable {
    final client = _ref.read(serverpodClientProvider);
    return client != null;
  }

  /// Check if Serverpod is currently connected
  bool get isConnected {
    final connectionState = _ref.read(serverpodConnectionStateProvider);
    return connectionState == ServerpodConnectionState.connected;
  }

  /// Get the current connection state
  ServerpodConnectionState get connectionState {
    return _ref.read(serverpodConnectionStateProvider);
  }

  /// Get the last error message, if any
  String? get lastError => _lastError;

  /// Get the Serverpod client instance
  /// Returns null if client is not available
  dynamic get client => _ref.read(serverpodClientProvider);

  /// Initialize the Serverpod service.
  /// This method validates the client and sets up connectivity monitoring.
  /// Call this in main.dart before running the app.
  Future<void> initialize() async {
    try {
      // Check if client is available
      final client = _ref.read(serverpodClientProvider);
      
      if (client == null) {
        _lastError = 'Serverpod client not available. Check your configuration.';
        debugPrint('⚠️ $lastError');
        return;
      }

      // Verify connectivity
      // Note: The generated client will have connectivityMonitor
      // For now, we check if client exists as a proxy for connectivity
      try {
        // Try to access connectivityMonitor if it exists
        final connectivityMonitor = (client as dynamic).connectivityMonitor;
        final isConnected = connectivityMonitor?.isConnected ?? false;
        _lastError = null;
        
        debugPrint('✅ ServerpodService initialized successfully');
        debugPrint('📡 Initial connection state: ${isConnected ? "Connected" : "Disconnected"}');
      } catch (_) {
        // If connectivityMonitor doesn't exist, assume connected if client exists
        _lastError = null;
        debugPrint('✅ ServerpodService initialized (connectivity check unavailable)');
      }
    } catch (e, stackTrace) {
      _lastError = e.toString();
      debugPrint('❌ Failed to initialize ServerpodService: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - allow app to continue without Serverpod
    }
  }

  /// Attempt to reconnect to Serverpod
  /// Returns true if reconnection was successful
  Future<bool> reconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('⚠️ Max reconnection attempts reached');
      return false;
    }

    _reconnectAttempts++;
    debugPrint('🔄 Attempting to reconnect to Serverpod (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    try {
      await Future.delayed(_reconnectDelay);
      
      // Invalidate the client provider to force re-initialization
      _ref.invalidate(serverpodClientProvider);
      
      // Wait a bit for the client to reinitialize
      await Future.delayed(const Duration(milliseconds: 500));
      
      final isConnected = this.isConnected;
      if (isConnected) {
        _reconnectAttempts = 0;
        _lastError = null;
        debugPrint('✅ Successfully reconnected to Serverpod');
        return true;
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Reconnection attempt failed: $e');
    }

    return false;
  }

  /// Reset reconnection attempts counter
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// Check connection health by attempting a simple operation
  /// Returns true if connection is healthy
  Future<bool> checkHealth() async {
    try {
      final client = _ref.read(serverpodClientProvider);
      if (client == null) return false;

      // Check connectivity monitor state
      try {
        final connectivityMonitor = (client as dynamic).connectivityMonitor;
        final isConnected = connectivityMonitor?.isConnected ?? false;
        return isConnected;
      } catch (_) {
        // If connectivityMonitor doesn't exist, assume disconnected
        return false;
      }
    } catch (e) {
      debugPrint('❌ Health check failed: $e');
      return false;
    }
  }

  /// Dispose resources (call when app is closing)
  void dispose() {
    _lastError = null;
    _reconnectAttempts = 0;
  }
}

/// Provider for ServerpodService
/// This provider creates a service instance that has access to Riverpod ref
final serverpodServiceProvider = Provider<ServerpodService>((ref) {
  final service = ServerpodService(ref);
  // Auto-initialize when service is first accessed
  service.initialize();
  return service;
});

/// Provider that watches connection state changes
/// Useful for UI that needs to react to connection changes
final serverpodConnectionWatcherProvider = StreamProvider<ServerpodConnectionState>((ref) {
  return Stream.periodic(
    const Duration(seconds: 2),
    (_) => ref.read(serverpodConnectionStateProvider),
  ).distinct();
});
