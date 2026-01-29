import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_provider.dart';
import 'providers/openai_provider.dart';
import 'providers/anthropic_provider.dart';
import 'providers/gemini_provider.dart';
import '../constants/env.dart';

/// Multi-provider AI service that supports multiple AI sources
/// with automatic fallback and provider selection
class MultiAIService {
  final List<AIProvider> _providers;
  AIProvider? _currentProvider;
  int _currentProviderIndex = 0;

  MultiAIService({
    List<AIProvider>? providers,
  }) : _providers = _buildProvidersList(providers) {
    _selectBestProvider();
  }

  /// Builds the full providers list from optional user list + env-configured providers.
  /// Does not mutate the user-provided list.
  static List<AIProvider> _buildProvidersList(List<AIProvider>? userProviders) {
    final fromEnv = <AIProvider>[];
    if (Env.openAiApiKey.isNotEmpty) {
      fromEnv.add(OpenAIProvider(apiKey: Env.openAiApiKey));
    }
    if (Env.anthropicApiKey.isNotEmpty) {
      fromEnv.add(AnthropicProvider(apiKey: Env.anthropicApiKey));
    }
    if (Env.geminiApiKey.isNotEmpty) {
      fromEnv.add(GeminiProvider(apiKey: Env.geminiApiKey));
    }
    return [...?userProviders, ...fromEnv];
  }

  /// Select the best available provider
  void _selectBestProvider() {
    // Find first available provider
    for (final provider in _providers) {
      if (provider.isAvailable) {
        _currentProvider = provider;
        _currentProviderIndex = _providers.indexOf(provider);
        debugPrint('✅ Selected AI provider: ${provider.name}');
        return;
      }
    }
    debugPrint('⚠️ No AI providers available');
  }

  /// Get current provider
  AIProvider? get currentProvider => _currentProvider;

  /// Get all available providers
  List<AIProvider> get availableProviders =>
      _providers.where((p) => p.isAvailable).toList();

  /// Get all providers (including unavailable)
  List<AIProvider> get allProviders => List.unmodifiable(_providers);

  /// Switch to a specific provider by name
  bool switchProvider(String providerName) {
    final provider = _providers.firstWhere(
      (p) => p.name.toLowerCase() == providerName.toLowerCase(),
      orElse: () => throw Exception('Provider not found: $providerName'),
    );

    if (!provider.isAvailable) {
      debugPrint('⚠️ Provider $providerName is not available');
      return false;
    }

    _currentProvider = provider;
    _currentProviderIndex = _providers.indexOf(provider);
    debugPrint('✅ Switched to AI provider: ${provider.name}');
    return true;
  }

  /// Switch to next available provider (round-robin)
  bool switchToNextProvider() {
    if (_providers.isEmpty) return false;

    int attempts = 0;
    while (attempts < _providers.length) {
      _currentProviderIndex = (_currentProviderIndex + 1) % _providers.length;
      final provider = _providers[_currentProviderIndex];

      if (provider.isAvailable) {
        _currentProvider = provider;
        debugPrint('✅ Switched to AI provider: ${provider.name}');
        return true;
      }
      attempts++;
    }

    return false;
  }

  /// Stream AI response with automatic fallback
  Stream<String> streamChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    bool enableFallback = true,
  }) async* {
    if (_currentProvider == null) {
      yield 'Error: No AI providers available. Please configure at least one API key.';
      return;
    }

    final providersToTry = enableFallback
        ? [
            _currentProvider!,
            ..._providers.where((p) => p != _currentProvider && p.isAvailable)
          ]
        : [_currentProvider!];

    for (final provider in providersToTry) {
      try {
        debugPrint('🤖 Using ${provider.name} for chat completion');
        yield* provider.streamChatCompletion(
          messages: messages,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
        return; // Success, exit
      } catch (e) {
        debugPrint('❌ ${provider.name} failed: $e');
        if (provider == providersToTry.last) {
          // Last provider failed
          yield 'Error: All AI providers failed. ${e.toString()}';
        }
        // Continue to next provider
      }
    }
  }

  /// Get chat completion with automatic fallback
  Future<String> getChatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    bool enableFallback = true,
  }) async {
    if (_currentProvider == null) {
      return 'Error: No AI providers available. Please configure at least one API key.';
    }

    final providersToTry = enableFallback
        ? [
            _currentProvider!,
            ..._providers.where((p) => p != _currentProvider && p.isAvailable)
          ]
        : [_currentProvider!];

    for (final provider in providersToTry) {
      try {
        debugPrint('🤖 Using ${provider.name} for chat completion');
        return await provider.getChatCompletion(
          messages: messages,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } catch (e) {
        debugPrint('❌ ${provider.name} failed: $e');
        if (provider == providersToTry.last) {
          // Last provider failed
          return 'Error: All AI providers failed. ${e.toString()}';
        }
        // Continue to next provider
      }
    }

    return 'Error: No available providers';
  }

  /// Check if any provider is available
  bool get isAvailable => _currentProvider != null && _currentProvider!.isAvailable;
}
