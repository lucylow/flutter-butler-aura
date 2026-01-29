import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/env.dart';

/// Result of submitting a goal to the A.U.R.A. backend (Lovable / aura-smart-home-agent).
class AuraGoalResult {
  final String summary;
  final String? planDescription;
  final bool success;

  const AuraGoalResult({
    required this.summary,
    this.planDescription,
    this.success = true,
  });
}

/// Service that talks to the A.U.R.A. backend (same API as the Lovable app).
/// When [Env.auraBackendUrl] is set, chat goals are sent here for orchestrated device control.
class AuraApiService {
  String get baseUrl => Env.auraBackendUrl.endsWith('/')
      ? Env.auraBackendUrl.substring(0, Env.auraBackendUrl.length - 1)
      : Env.auraBackendUrl;

  bool get isConfigured => Env.isAuraBackendConfigured();

  /// Submit a natural-language goal (e.g. "Set up for movie night", "I'm cold").
  /// Returns the backend's summary/confirmation text for display in chat.
  Future<AuraGoalResult> submitGoal(String goal) async {
    if (!isConfigured) {
      throw StateError('AURA_BACKEND_URL is not set');
    }

    final uri = Uri.parse('$baseUrl/api/aura/goal');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (Env.auraBackendToken.isNotEmpty)
        'Authorization': 'Bearer ${Env.auraBackendToken}',
    };
    final body = jsonEncode({'goal': goal.trim()});

    debugPrint('📤 A.U.R.A. goal: $uri');
    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    debugPrint('📥 A.U.R.A. goal response: ${response.statusCode}');

    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        message = data?['error']?['message'] as String? ??
            data?['message'] as String? ??
            response.body.isNotEmpty
                ? response.body
                : message;
      } catch (_) {}
      return AuraGoalResult(
        summary: message,
        success: false,
      );
    }

    String summary = '';
    String? planDescription;

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data != null) {
        summary = data['summary'] as String? ??
            data['message'] as String? ??
            data['text'] as String? ??
            data['data'] is Map
                ? (data['data'] as Map)['summary'] as String? ??
                    (data['data'] as Map)['message'] as String? ??
                    ''
                : '';
        planDescription = data['plan'] is Map
            ? (data['plan'] as Map)['description'] as String?
            : null;
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        summary = response.body;
      }
    }

    if (summary.isEmpty) {
      summary = 'Goal received. Check your devices for updates.';
    }

    return AuraGoalResult(
      summary: summary,
      planDescription: planDescription,
      success: true,
    );
  }
}

final auraApiServiceProvider = Provider<AuraApiService>((ref) {
  return AuraApiService();
});
