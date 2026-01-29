import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';
import '../../network/http_client.dart'
    show AppHttpClient, HttpClientConfig, ApiException, NetworkException;

/// Google Gemini API provider implementation
class GeminiProvider implements AIProvider {
  @override
  String get name => 'Google Gemini';

  final String apiKey;
  final String baseUrl;
  final String model;
  final AppHttpClient _httpClient;

  GeminiProvider({
    required this.apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
    this.model = 'gemini-pro',
    AppHttpClient? httpClient,
  }) : _httpClient = httpClient ?? AppHttpClient(
          config: const HttpClientConfig(
            timeout: Duration(seconds: 60),
            maxRetries: 2,
            enableLogging: true,
          ),
        );

  @override
  bool get isAvailable => apiKey.isNotEmpty;

  @override
  Stream<String> streamChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async* {
    if (!isAvailable) {
      yield 'Error: Google Gemini API key not configured.';
      return;
    }

    try {
      // Convert messages to Gemini format
      final geminiContents = <Map<String, dynamic>>[];
      
      // Add system instruction if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        geminiContents.add({
          'role': 'user',
          'parts': [{'text': systemPrompt}],
        });
        geminiContents.add({
          'role': 'model',
          'parts': [{'text': 'Understood. I will follow these instructions.'}],
        });
      }

      // Convert messages
      for (final msg in messages) {
        final role = msg['role'] == 'assistant' ? 'model' : 'user';
        final content = msg['content'] ?? '';
        geminiContents.add({
          'role': role,
          'parts': [{'text': content}],
        });
      }

      final uri = Uri.parse('$baseUrl/models/$model:streamGenerateContent')
          .replace(queryParameters: {'key': apiKey});

      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';

      request.body = jsonEncode({
        'contents': geminiContents,
        'generationConfig': {
          'temperature': temperature ?? 0.7,
          'maxOutputTokens': maxTokens ?? 500,
        },
      });

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        yield 'Error: ${_extractErrorMessage(errorBody, streamedResponse.statusCode)}';
        return;
      }

      // Parse streaming response
      String buffer = '';
      await for (final chunk in streamedResponse.stream.transform(const Utf8Decoder())) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.isEmpty) continue;

          try {
            final jsonData = jsonDecode(line);
            final candidates = jsonData['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            }
          } catch (_) {
            continue;
          }
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('⏰ Gemini stream timeout: $e');
      yield 'Error: Request to Google Gemini timed out. Please try again.';
    } on ApiException catch (e) {
      yield 'Error: ${e.message}';
    } on NetworkException catch (e) {
      yield 'Error: Network error - ${e.message}';
    } catch (e) {
      debugPrint('❌ Gemini stream error: $e');
      yield 'Error: Failed to connect to Google Gemini. Please try again.';
    }
  }

  static String _extractErrorMessage(String errorBody, int statusCode) {
    try {
      if (errorBody.isNotEmpty) {
        final errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
        if (errorJson != null) {
          final error = errorJson['error'];
          if (error is Map<String, dynamic>) {
            return error['message'] as String? ?? 'Failed to get AI response';
          }
          if (errorJson.containsKey('message')) {
            return errorJson['message'] as String;
          }
        }
      }
    } catch (_) {}
    return 'HTTP $statusCode - Failed to get AI response';
  }

  @override
  Future<String> getChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!isAvailable) {
      return 'Error: Google Gemini API key not configured.';
    }

    try {
      // Convert messages to Gemini format
      final geminiContents = <Map<String, dynamic>>[];
      
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        geminiContents.add({
          'role': 'user',
          'parts': [{'text': systemPrompt}],
        });
        geminiContents.add({
          'role': 'model',
          'parts': [{'text': 'Understood. I will follow these instructions.'}],
        });
      }

      for (final msg in messages) {
        final role = msg['role'] == 'assistant' ? 'model' : 'user';
        final content = msg['content'] ?? '';
        geminiContents.add({
          'role': role,
          'parts': [{'text': content}],
        });
      }

      final uri = Uri.parse('$baseUrl/models/$model:generateContent')
          .replace(queryParameters: {'key': apiKey});

      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'contents': geminiContents,
          'generationConfig': {
            'temperature': temperature ?? 0.7,
            'maxOutputTokens': maxTokens ?? 500,
          },
        },
      );

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonData['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        return 'Error: No response from Google Gemini';
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;

      if (parts == null || parts.isEmpty) {
        return 'Error: Empty response from Google Gemini';
      }

      final text = parts[0]['text'] as String?;
      return text ?? 'Error: No text in response';
    } on ApiException catch (e) {
      return 'Error: ${e.message}';
    } on NetworkException catch (e) {
      return 'Error: Network error - ${e.message}';
    } catch (e) {
      debugPrint('❌ Gemini getChatCompletion error: $e');
      return 'Error: Failed to connect to Google Gemini. Please try again.';
    }
  }
}
