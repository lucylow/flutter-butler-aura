import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/env.dart';
import 'aura_api_service.dart';

/// Calls A.U.R.A.-style APIs on your Serverpod server via HTTP.
/// Use when you run an aura_server that exposes goal + routine endpoints
/// (see SERVERPOD_AURA_API.md). Priority: AURA_BACKEND_URL > Serverpod > local AI.
class ServerpodAuraApi {
  String get baseUrl => Env.serverpodUrl.endsWith('/')
      ? Env.serverpodUrl.substring(0, Env.serverpodUrl.length - 1)
      : Env.serverpodUrl;

  /// True when SERVERPOD_URL is set and looks like a real base URL.
  bool get isConfigured {
    final url = Env.serverpodUrl.trim();
    return url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  /// Submit a goal to your Serverpod server (Lovable-style).
  /// Expects POST [baseUrl]/aura/submitGoal with body {"goal": "..."}.
  /// Returns summary text for chat; on error returns a result with success: false.
  Future<AuraGoalResult> submitGoal(String goal) async {
    if (!isConfigured) {
      throw StateError('SERVERPOD_URL is not set');
    }

    final uri = Uri.parse('$baseUrl/aura/submitGoal');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final body = jsonEncode({'goal': goal.trim()});

    debugPrint('📤 Serverpod Aura goal: $uri');
    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));
      debugPrint('📥 Serverpod Aura goal response: ${response.statusCode}');

      if (response.statusCode >= 400) {
        String message = 'Request failed (${response.statusCode})';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>?;
          message = data?['message'] as String? ??
              data?['error'] as String? ??
              (response.body.isNotEmpty ? response.body : message);
        } catch (_) {}
        return AuraGoalResult(summary: message, success: false);
      }

      String summary = '';
      String? planDescription;
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (data != null) {
          summary = data['summary'] as String? ??
              data['message'] as String? ??
              data['text'] as String? ??
              '';
          planDescription = data['plan'] is Map
              ? (data['plan'] as Map)['description'] as String?
              : null;
        }
      } catch (_) {
        if (response.body.trim().isNotEmpty) summary = response.body;
      }
      if (summary.isEmpty) summary = 'Goal received. Check your devices.';
      return AuraGoalResult(
        summary: summary,
        planDescription: planDescription,
        success: true,
      );
    } catch (e) {
      debugPrint('❌ Serverpod Aura goal error: $e');
      return AuraGoalResult(
        summary: 'Serverpod error: ${e.toString()}',
        success: false,
      );
    }
  }

  /// Run a routine by id on your Serverpod server.
  /// Expects POST [baseUrl]/routines/run with body {"id": "..."}.
  Future<void> runRoutine(String id) async {
    if (!isConfigured) {
      throw StateError('SERVERPOD_URL is not set');
    }

    final uri = Uri.parse('$baseUrl/routines/run');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final body = jsonEncode({'id': id});

    debugPrint('📤 Serverpod routine: $uri');
    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
      debugPrint('📥 Serverpod routine response: ${response.statusCode}');
      if (response.statusCode >= 400) {
        throw Exception(
          'Routine failed: ${response.statusCode} ${response.body.isNotEmpty ? response.body : ""}',
        );
      }
    } catch (e) {
      debugPrint('❌ Serverpod routine error: $e');
      rethrow;
    }
  }
}

final serverpodAuraApiProvider = Provider<ServerpodAuraApi>((ref) {
  return ServerpodAuraApi();
});
