import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/env.dart';
import '../network/http_client.dart'
    show AppHttpClient, HttpClientConfig, ApiException, NetworkException;
import 'multi_ai_service.dart';

/// Custom exception for AI service errors
class AIServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  AIServiceException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'AIServiceException: $message'
      '${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Service for interacting with AI models (OpenAI, Anthropic, etc.)
///
/// This is a legacy service. Consider using [MultiAIService] instead
/// for better provider support and automatic fallback.
class AIService {
  /// Shared system prompt used across streaming and non-streaming calls.
  ///
  /// Keeping this in a single place makes it easier to tweak behaviour
  /// without accidentally diverging between APIs or platforms (e.g. web / Chrome).
  static const String _systemPrompt = '''
You are Aura, an intelligent smart home assistant. You help users control their smart home devices, answer questions about their home, and provide helpful information. Be friendly, concise, and helpful. When users ask to control devices, acknowledge their request clearly.
''';

  /// Default API configuration constants
  static const String _defaultBaseUrl = 'https://api.openai.com/v1';
  static const String _defaultModel = 'gpt-4o-mini';
  static const String _chatCompletionsEndpoint = '/chat/completions';
  static const Duration _minRequestInterval = Duration(milliseconds: 100);
  static const Duration _defaultTimeout = Duration(seconds: 60);
  static const int _defaultMaxRetries = 2;
  static const double _defaultTemperature = 0.7;
  static const int _defaultMaxTokens = 500;
  static const String _sseDataPrefix = 'data: ';
  static const String _sseDoneMarker = '[DONE]';
  static const String _errorPrefix = 'Error: ';

  final String apiKey;
  final String baseUrl;
  final String model;
  final AppHttpClient _httpClient;
  DateTime? _lastRequestTime;
  bool _disposed = false;

  /// Creates an instance of AIService.
  ///
  /// [apiKey] is required and should be a valid API key for the AI provider.
  /// [baseUrl] defaults to OpenAI's API endpoint but can be customized.
  /// [model] specifies which AI model to use (defaults to 'gpt-4o-mini').
  /// [httpClient] allows injecting a custom HTTP client for testing or customization.
  AIService({
    required this.apiKey,
    this.baseUrl = _defaultBaseUrl,
    this.model = _defaultModel,
    AppHttpClient? httpClient,
  }) : _httpClient = httpClient ?? AppHttpClient(
          config: const HttpClientConfig(
            timeout: _defaultTimeout,
            maxRetries: _defaultMaxRetries,
            enableLogging: true,
          ),
        ) {
    _setupHttpClient();
  }

  /// Sets up HTTP client interceptors and configuration
  void _setupHttpClient() {
    // Add authorization header interceptor
    _httpClient.addRequestInterceptor((request) {
      if (apiKey.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $apiKey';
      }
    });
  }

  /// Validates that the service is properly configured and not disposed.
  ///
  /// Throws [AIServiceException] if validation fails.
  void _validateService() {
    if (_disposed) {
      throw AIServiceException('Service has been disposed');
    }
    if (apiKey.isEmpty) {
      throw AIServiceException(
        'AI API key not configured. Please set OPENAI_API_KEY in your environment.',
      );
    }
  }

  /// Rate limiting helper to avoid hitting provider limits,
  /// especially important in browsers where users can trigger
  /// multiple rapid interactions (e.g. double‑clicks in Chrome).
  Future<void> _rateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Builds the common request payload for chat completions.
  ///
  /// [messages] is the list of conversation messages (role + content).
  /// [stream] indicates whether to use streaming mode.
  /// [systemPrompt] overrides the default system prompt when provided.
  /// [temperature] controls randomness (0.0 to 2.0).
  /// [maxTokens] limits the maximum number of tokens in the response.
  Map<String, dynamic> _buildRequestBody(
    List<Map<String, String>> messages, {
    required bool stream,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) {
    return {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt ?? _systemPrompt,
        },
        ...messages,
      ],
      'stream': stream,
      'temperature': temperature ?? _defaultTemperature,
      'max_tokens': maxTokens ?? _defaultMaxTokens,
    };
  }

  /// Returns a user-facing error string with the standard prefix.
  String _err(String message) => '$_errorPrefix$message';

  /// Extracts error message from API error response.
  ///
  /// Handles various error response formats from AI providers.
  String _extractErrorMessage(dynamic errorBody, int statusCode) {
    try {
      if (errorBody is String && errorBody.isNotEmpty) {
        final errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
        if (errorJson != null) {
          final error = errorJson['error'];
          if (error is Map<String, dynamic>) {
            final msg = error['message'];
            return msg?.toString() ?? 'Failed to get AI response';
          }
          if (errorJson.containsKey('message')) {
            final msg = errorJson['message'];
            return msg?.toString() ?? 'Failed to get AI response';
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to parse error response: $e');
    }
    return 'HTTP $statusCode - Failed to get AI response';
  }

  /// Streams AI response tokens for a given message.
  ///
  /// Returns a Stream of strings representing the response tokens.
  /// [messages] is the conversation history.
  /// [systemPrompt] overrides the default Aura system prompt when provided.
  /// [onToken] is an optional callback that gets called for each token received.
  /// [temperature] controls randomness (0.0 to 2.0).
  /// [maxTokens] limits the maximum number of tokens in the response.
  ///
  /// Throws [AIServiceException] if the service is not properly configured.
  Stream<String> streamChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    Function(String)? onToken,
    double? temperature,
    int? maxTokens,
  }) async* {
    _validateService();
    await _rateLimit();

    try {
      final uri = Uri.parse('$baseUrl$_chatCompletionsEndpoint');
      final request = http.Request('POST', uri);

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      request.body = jsonEncode(
        _buildRequestBody(
          messages,
          stream: true,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
      );

      final streamedResponse = await _httpClient.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        final errorMessage = _extractErrorMessage(
          errorBody,
          streamedResponse.statusCode,
        );
        yield '$_errorPrefix$errorMessage';
        return;
      }

      // Parse streaming response (Server-Sent Events format)
      yield* _parseStreamingResponse(streamedResponse.stream, onToken);
    } on TimeoutException catch (e) {
      debugPrint('⏰ Timeout in streamChatCompletion: $e');
      yield 'Error: Request to AI service timed out. Please try again.';
    } on ApiException catch (e) {
      yield 'Error: ${e.message}';
    } on NetworkException catch (e) {
      yield 'Error: Network error - ${e.message}';
    } on AIServiceException catch (e) {
      yield 'Error: ${e.message}';
    } catch (e) {
      debugPrint('❌ Unexpected error in streamChatCompletion: $e');
      yield 'Error: Failed to connect to AI service. Please try again.';
    }
  }

  static final RegExp _sseLineSplit = RegExp(r'\r?\n');

  /// Parses Server-Sent Events (SSE) streaming response.
  ///
  /// Handles both LF and CRLF line endings and extracts content tokens.
  Stream<String> _parseStreamingResponse(
    Stream<List<int>> responseStream,
    Function(String)? onToken,
  ) async* {
    final buffer = StringBuffer();
    await for (final chunk in responseStream.transform(const Utf8Decoder())) {
      buffer.write(chunk);
      final bufferStr = buffer.toString();
      buffer.clear();
      final lines = bufferStr.split(_sseLineSplit);
      buffer.write(lines.removeLast()); // Keep incomplete line in buffer

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || !trimmed.startsWith(_sseDataPrefix)) {
          continue;
        }

        final data = trimmed.substring(_sseDataPrefix.length).trim();
        if (data == _sseDoneMarker) {
          return;
        }

        final content = _extractContentFromSSE(data);
        if (content != null && content.isNotEmpty) {
          onToken?.call(content);
          yield content;
        }
      }
    }

    // Process any remaining buffer content
    final remaining = buffer.toString();
    if (remaining.isNotEmpty && remaining.startsWith(_sseDataPrefix)) {
      final data = remaining.substring(_sseDataPrefix.length).trim();
      if (data != _sseDoneMarker) {
        final content = _extractContentFromSSE(data);
        if (content != null && content.isNotEmpty) {
          onToken?.call(content);
          yield content;
        }
      }
    }
  }

  /// Extracts content from a single SSE data line.
  ///
  /// Returns the content string if found, null otherwise.
  String? _extractContentFromSSE(String data) {
    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>?;
      if (jsonData == null) return null;

      final choices = jsonData['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;

      final choice = choices[0] as Map<String, dynamic>?;
      if (choice == null) return null;

      final delta = choice['delta'] as Map<String, dynamic>?;
      if (delta == null) return null;

      final content = delta['content'] as String?;
      return content;
    } catch (e) {
      // Skip malformed JSON lines
      debugPrint('⚠️ Failed to parse SSE data: $data - $e');
      return null;
    }
  }

  /// Non-streaming version for simpler use cases.
  ///
  /// [messages] is the conversation history.
  /// [systemPrompt] overrides the default Aura system prompt when provided.
  /// [temperature] controls randomness (0.0 to 2.0).
  /// [maxTokens] limits the maximum number of tokens in the response.
  ///
  /// Returns the complete AI response as a string.
  /// Throws [AIServiceException] if the service is not properly configured.
  Future<String> getChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    _validateService();
    await _rateLimit();

    try {
      final uri = Uri.parse('$baseUrl$_chatCompletionsEndpoint');
      final response = await _httpClient.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: _buildRequestBody(
          messages,
          stream: false,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
      );

      if (response.statusCode != 200) {
        final errorMessage = _extractErrorMessage(
          response.body,
          response.statusCode,
        );
        return _err(errorMessage);
      }

      return _extractContentFromResponse(response.body);
    } on ApiException catch (e) {
      debugPrint('❌ API error in getChatCompletion: ${e.message}');
      return _err(e.message);
    } on NetworkException catch (e) {
      debugPrint('❌ Network error in getChatCompletion: ${e.message}');
      return _err('Network error - ${e.message}');
    } on AIServiceException catch (e) {
      return _err(e.message);
    } catch (e) {
      debugPrint('❌ Unexpected error in getChatCompletion: $e');
      return _err('Failed to connect to AI service. Please try again.');
    }
  }

  /// Extracts content from a non-streaming API response.
  ///
  /// Returns the content string or an error message if parsing fails.
  String _extractContentFromResponse(String responseBody) {
    try {
      final jsonData = jsonDecode(responseBody) as Map<String, dynamic>?;
      if (jsonData == null) {
        return '$_errorPrefix Invalid response format from AI service';
      }

      final choices = jsonData['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        return '$_errorPrefix No response from AI';
      }

      final choice = choices[0] as Map<String, dynamic>?;
      if (choice == null) {
        return '$_errorPrefix Invalid choice format in AI response';
      }

      final message = choice['message'] as Map<String, dynamic>?;
      if (message == null) {
        return '$_errorPrefix Invalid message format in AI response';
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        return '$_errorPrefix Empty response from AI';
      }

      return content;
    } catch (e) {
      debugPrint('❌ Failed to parse AI response JSON: $e');
      return '$_errorPrefix Failed to parse AI response. Please try again.';
    }
  }

  /// Disposes resources and marks the service as disposed.
  ///
  /// After calling this method, the service should not be used.
  /// Subsequent calls will throw [AIServiceException].
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _httpClient.close();
  }

  /// Checks if the service has been disposed.
  bool get isDisposed => _disposed;
}

/// Provider for AI Service (legacy - use [multiAIServiceProvider] instead)
///
/// This provider creates a single-provider AI service instance.
/// For better functionality, use [multiAIServiceProvider] which supports
/// multiple AI providers with automatic fallback.
final aiServiceProvider = Provider<AIService>((ref) {
  // Get API key from environment or use empty string as fallback
  // In production, use a secure method to store API keys
  const apiKey = Env.openAiApiKey;
  final service = AIService(apiKey: apiKey);

  // Dispose service when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for Multi-AI Service (supports multiple AI providers)
///
/// This is the recommended provider to use as it supports multiple
/// AI providers (OpenAI, Anthropic, Gemini) with automatic fallback.
final multiAIServiceProvider = Provider<MultiAIService>((ref) {
  final service = MultiAIService();
  // Note: MultiAIService doesn't currently have a dispose method,
  // but if it did, we would call it here in ref.onDispose
  return service;
});
