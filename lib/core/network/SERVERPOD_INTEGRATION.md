# Serverpod Integration Guide

This document describes the improved Serverpod integration in the Aura Flutter app.

## Overview

The Serverpod integration has been enhanced with:
- ✅ Proper Riverpod provider integration
- ✅ Reactive connection state management
- ✅ Automatic retry and reconnection logic
- ✅ Comprehensive error handling
- ✅ Helper utilities for common operations
- ✅ Graceful degradation when Serverpod is not configured

## Architecture

### Core Components

1. **`serverpod_client.dart`** - Client provider and connection state management
2. **`serverpod_service.dart`** - Service layer for connection lifecycle management
3. **`serverpod_helpers.dart`** - Utility functions for common operations

### Providers

- `serverpodClientProvider` - Provides the Serverpod client instance (null until configured)
- `serverpodClientAvailableProvider` - Boolean indicating if client is available
- `serverpodConnectionStateProvider` - Current connection state (connected/disconnected/connecting/error)
- `serverpodServiceProvider` - Service instance with connection management
- `serverpodConnectionWatcherProvider` - Stream of connection state changes

## Setup Instructions

### 1. Create Serverpod Server Project

```bash
serverpod create aura_server
cd aura_server
```

### 2. Generate Client Code

After creating your endpoints in the server project:

```bash
serverpod generate
```

This generates the client package in `aura_server/aura_server_client/`.

### 3. Add Generated Client to Flutter Project

Add to `pubspec.yaml`:

```yaml
dependencies:
  aura_server_client:
    path: ../aura_server/aura_server_client
```

### 4. Configure Client Provider

Edit `lib/core/network/serverpod_client.dart`:

1. Uncomment the import:
   ```dart
   import 'package:aura_server_client/aura_server_client.dart';
   import 'package:serverpod_flutter/serverpod_flutter.dart';
   ```

2. Replace `Provider<dynamic>` with `Provider<Client>` (or your generated client class name)

3. Uncomment and configure the client initialization code

### 5. Configure Server URL

Set the Serverpod URL via environment variable or update `lib/core/constants/env.dart`:

```dart
static const String serverpodUrl = 
    String.fromEnvironment('SERVERPOD_URL',
        defaultValue: 'https://your-server.com/');
```

Or run with:
```bash
flutter run --dart-define=SERVERPOD_URL=https://your-server.com/
```

## Usage Examples

### Basic Usage

```dart
// Get the client
final client = ref.read(serverpodClientProvider);
if (client != null) {
  // Use your generated endpoints
  final result = await client.myEndpoint.doSomething();
}
```

### Check Connection State

```dart
// Using the service
final service = ref.read(serverpodServiceProvider);
if (service.isConnected) {
  // Serverpod is connected
}

// Using the provider directly
final connectionState = ref.watch(serverpodConnectionStateProvider);
switch (connectionState) {
  case ServerpodConnectionState.connected:
    // Handle connected state
    break;
  case ServerpodConnectionState.disconnected:
    // Handle disconnected state
    break;
  // ...
}
```

### Using Helper Utilities

```dart
// Execute with automatic retry
final result = await ServerpodHelpers.executeWithRetry(
  ref,
  () => client.myEndpoint.doSomething(),
  maxRetries: 3,
);

// Execute only if connected
final result = await ServerpodHelpers.executeIfConnected(
  ref,
  () => client.myEndpoint.doSomething(),
);

// Check if ready
if (ServerpodHelpers.isReady(ref)) {
  // Serverpod is ready to use
}

// Get connection status message for UI
final status = ServerpodHelpers.getConnectionStatusMessage(ref);
```

### Reconnection

```dart
final service = ref.read(serverpodServiceProvider);
if (!service.isConnected) {
  final reconnected = await service.reconnect();
  if (reconnected) {
    // Successfully reconnected
  }
}
```

### Watching Connection Changes

```dart
final connectionWatcher = ref.watch(serverpodConnectionWatcherProvider);
connectionWatcher.when(
  data: (state) {
    // Handle connection state changes
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

## Features

### Automatic Reconnection

The service includes automatic reconnection logic with configurable retry attempts and delays.

### Error Handling

All operations include comprehensive error handling that prevents crashes and provides useful error messages.

### Graceful Degradation

The app continues to work even if Serverpod is not configured. All providers return null or safe defaults when the client is unavailable.

### Reactive State Management

Connection state changes automatically trigger provider updates, allowing UI to react to connection changes.

## Testing

The integration is designed to work without a Serverpod server for development. When the client is not configured, all providers return null or safe defaults.

For testing with a mock server, you can:
1. Use the `setConnectionState` method (marked `@visibleForTesting`)
2. Mock the `serverpodClientProvider` in tests
3. Use the helper utilities which handle null clients gracefully

## Troubleshooting

### Client Always Returns Null

- Check that you've generated the client from your server project
- Verify the client package is added to `pubspec.yaml`
- Ensure the import path is correct in `serverpod_client.dart`
- Check that the Serverpod URL is configured correctly

### Connection State Always Disconnected

- Verify your Serverpod server is running
- Check the server URL is correct
- Ensure network connectivity
- Check server logs for connection errors

### Reconnection Not Working

- Check `_maxReconnectAttempts` and `_reconnectDelay` in `serverpod_service.dart`
- Verify the server is accessible
- Check error logs for reconnection failures

## Aura API (Lovable-style goals + routines)

When `SERVERPOD_URL` is set, the app also calls **HTTP** endpoints for goal-oriented chat and routines (no generated client required):

- **POST** `$SERVERPOD_URL/aura/submitGoal` — body `{"goal": "..."}` → returns `{ "summary": "...", "plan": { "description": "..." } }`
- **POST** `$SERVERPOD_URL/routines/run` — body `{"id": "goodnight"}` → 200 OK

See **[SERVERPOD_AURA_API.md](SERVERPOD_AURA_API.md)** for the full API contract and example Serverpod endpoint code. This lets the Flutter Chrome app work like the [Lovable app](https://tuya-aura.lovable.app) with Serverpod as the backend.

## Next Steps

1. Create your Serverpod server endpoints (and Aura HTTP routes per SERVERPOD_AURA_API.md)
2. Generate the client code (optional; Aura API uses HTTP)
3. Configure the client provider as described above
4. Start using Serverpod endpoints in your app!
