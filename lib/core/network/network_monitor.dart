import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity state
enum NetworkStatus {
  connected,
  disconnected,
  unknown,
}

/// Network monitor for tracking connectivity status
class NetworkMonitor {
  NetworkStatus _status = NetworkStatus.unknown;
  final _statusController = StreamController<NetworkStatus>.broadcast();
  
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  NetworkStatus get status => _status;

  NetworkMonitor() {
    _initialize();
  }

  void _initialize() {
    // In a real implementation, you would use connectivity_plus package
    // For now, we'll assume connected by default
    _updateStatus(NetworkStatus.connected);
  }

  void _updateStatus(NetworkStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
      debugPrint('📡 Network status changed: ${newStatus.name}');
    }
  }

  /// Manually set network status (useful for testing)
  @visibleForTesting
  void setStatus(NetworkStatus status) {
    _updateStatus(status);
  }

  /// Check if network is connected
  bool get isConnected => _status == NetworkStatus.connected;

  void dispose() {
    _statusController.close();
  }
}

/// Provider for network monitor
final networkMonitorProvider = Provider<NetworkMonitor>((ref) {
  final monitor = NetworkMonitor();
  ref.onDispose(() {
    monitor.dispose();
  });
  return monitor;
});
