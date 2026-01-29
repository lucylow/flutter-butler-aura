import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/env.dart';

/// Serverpod client provider with proper initialization and error handling.
/// 
/// This provider creates and manages a Serverpod client instance.
/// The client will be null if:
/// - Serverpod URL is not configured
/// - Client initialization fails
/// - Generated client is not available
/// 
/// TO USE WITH GENERATED CLIENT:
/// 1. Create a Serverpod server project: `serverpod create aura_server`
/// 2. Generate the client code in your server project
/// 3. Add the generated client package to your `pubspec.yaml`:
///    dependencies:
///      aura_server_client:
///        path: ../aura_server/aura_server_client
/// 4. Import the generated Client class:
///    import 'package:aura_server_client/aura_server_client.dart';
/// 5. Replace `dynamic` with your generated client class name (usually `Client`)
/// 6. Uncomment and update the client initialization code below

/// Base Serverpod client provider
/// Returns null until a generated client is configured
/// 
/// NOTE: The base serverpod_client package does not export a Client class.
/// You must generate a client from your Serverpod server project.
final serverpodClientProvider = Provider<dynamic>((ref) {
  try {
    const serverUrl = Env.serverpodUrl;
    if (serverUrl.isEmpty || serverUrl == 'http://localhost:8080/') {
      debugPrint('⚠️ Serverpod URL not configured (using default localhost)');
      // Return null for unconfigured localhost in production
      if (kReleaseMode) {
        return null;
      }
    }
    
    // TODO: Uncomment and configure when you have a generated client:
    // 
    // import 'package:aura_server_client/aura_server_client.dart';
    // import 'package:serverpod_flutter/serverpod_flutter.dart';
    // 
    // final normalizedUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
    // final client = Client(
    //   normalizedUrl,
    //   authenticationKeyManager: FlutterAuthenticationKeyManager(),
    // )..connectivityMonitor = FlutterConnectivityMonitor();
    // 
    // client.connectivityMonitor?.addListener(() {
    //   final isConnected = client.connectivityMonitor?.isConnected ?? false;
    //   debugPrint('📡 Serverpod connectivity: ${isConnected ? "Connected" : "Disconnected"}');
    //   ref.invalidateSelf();
    // });
    // 
    // debugPrint('✅ Serverpod client initialized: $normalizedUrl');
    // return client;
    
    debugPrint('⚠️ Serverpod client not configured - generated client required');
    return null;
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize Serverpod client: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
});

/// Provider that checks if Serverpod client is available
final serverpodClientAvailableProvider = Provider<bool>((ref) {
  final client = ref.watch(serverpodClientProvider);
  return client != null;
});

/// Provider for Serverpod connection state
final serverpodConnectionStateProvider = Provider<ServerpodConnectionState>((ref) {
  final client = ref.watch(serverpodClientProvider);
  
  if (client == null) {
    return ServerpodConnectionState.disconnected;
  }
  
  try {
    // Try to access connectivityMonitor if it exists on the generated client
    final connectivityMonitor = (client as dynamic).connectivityMonitor;
    final isConnected = connectivityMonitor?.isConnected ?? false;
    return isConnected 
        ? ServerpodConnectionState.connected 
        : ServerpodConnectionState.disconnected;
  } catch (_) {
    // If connectivityMonitor doesn't exist, assume disconnected
    return ServerpodConnectionState.disconnected;
  }
});

/// Connection state enum for Serverpod
enum ServerpodConnectionState {
  connected,
  disconnected,
  connecting,
  error,
}
