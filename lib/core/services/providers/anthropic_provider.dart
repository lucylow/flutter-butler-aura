import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';
import '../../network/http_client.dart';

/// Anthropic Claude API provider implementation
class AnthropicProvider implements AIProvider {
  @override
  String get name => 'Anthropic Claude';

  final String apiKey;
  final String baseUrl;
  final String model;
  final AppHttpClient _httpClient;

  AnthropicProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com/v1',
    this.model = 'claude-3-haiku-20240307',
    AppHttpClient? httpClient,
  }) : _httpClient = httpClient ?? AppHttpClient(
          config: const HttpClientConfig(
            timeout: Duration(seconds: 60),
            maxRetries: 2,
            enableLogging: true,
          ),
        ) {
    _httpClient.addRequestInterceptor((request) {
      if (apiKey.isNotEmpty) {
        request.headers['x-api-key'] = apiKey;
        request.headers['anthropic-version'] = '2023-06-01';
      }
    });
  }

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
      yield 'Error: Anthropic API key not configured.';
      return;
    }

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/messages'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      });

      // Convert messages format (Anthropic uses different format)
      final anthropicMessages = messages.map((msg) {
        return {
          'role': msg['role'] == 'assistant' ? 'assistant' : 'user',
          'content': msg['content'] ?? '',
        };
      }).toList();

      final body = <String, dynamic>{
        'model': model,
        'messages': anthropicMessages,
        'max_tokens': maxTokens ?? 500,
        'stream': true,
      };

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        body['system'] = systemPrompt;
      }

      if (temperature != null) {
        body['temperature'] = temperature;
      }

      request.body = jsonEncode(body);

      final streamedResponse = await _httpClient.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        yield 'Error: ${_extractErrorMessage(errorBody, streamedResponse.statusCode)}';
        return;
      }

      // Parse streaming response (Server-Sent Events format)
      String buffer = '';
      await for (final chunk in streamedResponse.stream.transform(const Utf8Decoder())) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.isEmpty || !line.startsWith('data: ')) continue;

          final data = line.substring(6).trim();
          if (data == '[DONE]') return;

          try {
            final jsonData = jsonDecode(data);
            if (jsonData['type'] == 'content_block_delta') {
              final delta = jsonData['delta'] as Map<String, dynamic>?;
              final text = delta?['text'] as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      yield 'Error: Failed to connect to Anthropic. ${e.toString()}';
    }
  }

  @override
  Future<String> getChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!isAvailable) {
      return 'Error: Anthropic API key not configured.';
    }

    try {
      // Convert messages format
      final anthropicMessages = messages.map((msg) {
        return {
          'role': msg['role'] == 'assistant' ? 'assistant' : 'user',
          'content': msg['content'] ?? '',
        };
      }).toList();

      final body = <String, dynamic>{
        'model': model,
        'messages': anthropicMessages,
        'max_tokens': maxTokens ?? 500,
      };

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        body['system'] = systemPrompt;
      }

      if (temperature != null) {
        body['temperature'] = temperature;
      }

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: body,
      );

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final content = jsonData['content'] as List?;

      if (content == null || content.isEmpty) {
        return 'Error: No response from Anthropic';
      }

      // Extract text from content blocks
      final textBlocks = content
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'] as String)
          .join('');

      return textBlocks.isEmpty ? 'Error: Empty response from Anthropic' : textBlocks;
    } on ApiException catch (e) {
      return 'Error: ${e.message}';
    } on NetworkException catch (e) {
      return 'Error: Network error - ${e.message}';
    } catch (e) {
      debugPrint('❌ Anthropic getChatCompletion error: $e');
      return 'Error: Failed to connect to Anthropic. Please try again.';
    }
  }

  String _extractErrorMessage(String errorBody, int statusCode) {
    try {
      final json = jsonDecode(errorBody) as Map<String, dynamic>?;
      if (json == null) return 'HTTP $statusCode';
      final error = json['error'] as Map<String, dynamic>?;
      if (error != null) {
        final msg = error['message'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
      }
      final msg = json['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {}
    return errorBody.isNotEmpty ? errorBody : 'HTTP $statusCode';
  }
}
