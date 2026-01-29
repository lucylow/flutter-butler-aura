# Serverpod Aura API — Lovable-Style Backend

This document defines the HTTP API that the Flutter app calls when `SERVERPOD_URL` is set. Implement these endpoints in your Serverpod server so the app works like the [Lovable app](https://tuya-aura.lovable.app) / [aura-smart-home-agent](https://github.com/lucylow/aura-smart-home-agent) with Serverpod as the backend.

## Base URL

- Flutter uses `Env.serverpodUrl` (e.g. `http://localhost:8080/` or `https://your-server.com/`).
- All paths below are relative to that base.

---

## 1. Submit goal (goal-oriented orchestration)

**POST** `/aura/submitGoal`

Same semantics as the Lovable app: user sends a natural-language goal; the server (orchestrator) plans and executes device actions, then returns a summary.

### Request

```http
POST /aura/submitGoal
Content-Type: application/json

{"goal": "Set up for movie night"}
```

### Response (success)

```json
{
  "summary": "Movie night scene activated. Lights dimmed, thermostat set to 72°F, and speakers ready.",
  "plan": {
    "description": "1. Dim living room lights 2. Set thermostat 3. Enable audio"
  }
}
```

- `summary` (string, required): Shown in chat as A.U.R.A.’s reply.
- `plan.description` (string, optional): Appended below the summary if present.

### Response (error)

- Status `4xx` or `5xx`.
- Body can include `{"message": "..."}` or `{"error": "..."}`; the app will show it in chat.

### Example Serverpod endpoint (Dart, server project)

Create a new endpoint in your Serverpod server (e.g. `lib/src/endpoints/aura_endpoint.dart`):

```dart
import 'package:serverpod/serverpod.dart';

class AuraEndpoint extends Endpoint {
  /// Submit a goal (Lovable-style). Call your orchestrator / Tuya backend here.
  Future<Map<String, dynamic>> submitGoal(Session session, String goal) async {
    // TODO: Call your A.U.R.A. orchestrator, Tuya APIs, or proxy to aura-smart-home-agent backend.
    // Example: call external API
    // final response = await HttpClient().post(
    //   Uri.parse('https://your-aura-backend.com/api/aura/goal'),
    //   body: jsonEncode({'goal': goal}),
    // );
    return {
      'summary': 'Goal received: "$goal". Configure your orchestrator in AuraEndpoint.',
      'plan': {'description': '1. Parse goal 2. Execute device actions'},
    };
  }
}
```

Then expose an HTTP route that maps `POST /aura/submitGoal` to this method (e.g. via a custom route that reads JSON body `goal` and calls `submitGoal`). If you use Serverpod’s built-in endpoint invocation, ensure the path and method match what the Flutter app expects.

---

## 2. Run routine

**POST** `/routines/run`

Runs a routine by id (e.g. `goodnight`, `leave_home`, `lock_doors`).

### Request

```http
POST /routines/run
Content-Type: application/json

{"id": "goodnight"}
```

### Response (success)

- Status `200` (body optional). The app only checks status.

### Response (error)

- Status `4xx` or `5xx`; the app may show a snackbar or fall back to demo behavior.

### Example Serverpod endpoint (Dart, server project)

```dart
import 'package:serverpod/serverpod.dart';

class RoutinesEndpoint extends Endpoint {
  /// Run a routine by id. Trigger device actions or proxy to your backend.
  Future<void> run(Session session, String id) async {
    // TODO: Map id to device actions (Tuya, Supabase, etc.)
    switch (id) {
      case 'goodnight':
        // await session.aura.turnOffLights(); etc.
        break;
      case 'leave_home':
        // await session.aura.armSecurity(); etc.
        break;
      default:
        break;
    }
  }
}
```

Expose `POST /routines/run` that reads JSON `{"id": "..."}` and calls `run(session, id)`.

---

## Flutter usage

- **Goals (chat):** If `AURA_BACKEND_URL` is not set but `SERVERPOD_URL` is, the app calls `POST $SERVERPOD_URL/aura/submitGoal` and shows the returned `summary` (and optional `plan.description`) in chat.
- **Routines (dashboard):** When the user taps a routine, the app calls `POST $SERVERPOD_URL/routines/run` with `{"id": "<routineId>"}` when Serverpod Aura API is configured; otherwise it uses the local demo (delay).

---

## Optional: proxy to aura-smart-home-agent

Your Serverpod server can proxy to the Node/Lovable backend so you don’t reimplement orchestration:

- `AuraEndpoint.submitGoal`: HTTP POST to `AURA_BACKEND_URL/api/aura/goal` with `{"goal": goal}`, then return the JSON response (or map it to `summary` + `plan`).
- `RoutinesEndpoint.run`: Map routine ids to the same backend’s routines API if it exists, or implement device calls yourself.

This keeps the Flutter app unchanged while moving configuration (backend URL, keys) to the server.
