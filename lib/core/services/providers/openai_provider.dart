import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';
import '../../network/http_client.dart'
    show AppHttpClient, HttpClientConfig, ApiException, NetworkException;

/// OpenAI API provider implementation
class OpenAIProvider implements AIProvider {
  @override
  String get name => 'OpenAI';

  final String apiKey;
  final String baseUrl;
  final String model;
  final AppHttpClient _httpClient;

  OpenAIProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
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
        request.headers['Authorization'] = 'Bearer $apiKey';
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
      yield 'Error: OpenAI API key not configured.';
      return;
    }

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/chat/completions'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });

      final messageList = <Map<String, String>>[];
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messageList.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      messageList.addAll(messages);

      request.body = jsonEncode({
        'model': model,
        'messages': messageList,
        'stream': true,
        'temperature': temperature ?? 0.7,
        'max_tokens': maxTokens ?? 500,
      });

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        try {
          final errorJson = jsonDecode(errorBody);
          yield 'Error: ${errorJson['error']?['message'] ?? 'Failed to get AI response'}';
        } catch (e) {
          yield 'Error: HTTP ${streamedResponse.statusCode} - Failed to get AI response';
        }
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
            final choices = jsonData['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      yield 'Error: Failed to connect to OpenAI. ${e.toString()}';
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
      return 'Error: OpenAI API key not configured.';
    }

    try {
      final messageList = <Map<String, String>>[];
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messageList.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      messageList.addAll(messages);

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'model': model,
          'messages': messageList,
          'temperature': temperature ?? 0.7,
          'max_tokens': maxTokens ?? 500,
        },
      );

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>?;
      final choices = jsonData?['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        return 'Error: No response from OpenAI';
      }

      final message = (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.isEmpty) {
        return 'Error: Empty response from OpenAI';
      }
      return content;
    } on ApiException catch (e) {
      return 'Error: ${e.message}';
    } on NetworkException catch (e) {
      return 'Error: Network error - ${e.message}';
    } catch (e) {
      debugPrint('❌ OpenAI getChatCompletion error: $e');
      return 'Error: Failed to connect to OpenAI. Please try again.';
    }
  }
}
