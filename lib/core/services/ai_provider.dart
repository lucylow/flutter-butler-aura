import 'dart:async';

/// Abstract interface for AI providers
/// Allows switching between different AI services (OpenAI, Anthropic, Gemini, etc.)
abstract class AIProvider {
  /// Provider name for identification
  String get name;

  /// Check if this provider is available (has API key configured)
  bool get isAvailable;

  /// Stream AI response tokens for a given message
  Stream<String> streamChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  });

  /// Non-streaming version for simpler use cases
  Future<String> getChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  });
}
