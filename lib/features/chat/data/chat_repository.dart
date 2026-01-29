import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/env.dart';
import '../../../core/network/aura_api_service.dart';
import '../../../core/network/serverpod_aura_api.dart';
import '../../../core/network/serverpod_service.dart';
import '../../../core/services/ai_service.dart';
import '../domain/chat_message.dart';

/// Chat state model
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isConnected;
  final String? error;

  const ChatState({
    this.messages = const [], 
    this.isLoading = false,
    this.isConnected = true,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isConnected,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Chat notifier managing chat state and AI interactions
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  final List<Map<String, String>> _conversationHistory = [];

  ChatNotifier(this.ref) : super(const ChatState()) {
    _initialize();
  }

  void _initialize() {
    // Connection: A.U.R.A. backend (Lovable-style) > Serverpod > AI providers
    final auraBackend = Env.isAuraBackendConfigured();
    final service = ref.read(serverpodServiceProvider);
    final multiAIService = ref.read(multiAIServiceProvider);
    final isConnected = auraBackend ||
        service.isConnected ||
        multiAIService.isAvailable;
    state = state.copyWith(isConnected: isConnected);

    String greeting;
    if (auraBackend) {
      greeting =
          "Hello! I'm A.U.R.A., your Home Executive. Tell me a goal—e.g. \"Set up for movie night\" or \"I'm cold\"—and I'll orchestrate your devices.";
    } else if (multiAIService.isAvailable) {
      greeting =
          "Hello! I'm Aura. How can I help you with your smart home today?";
    } else {
      greeting =
          "Hello! I'm Aura. Set AURA_BACKEND_URL to use the Lovable-style backend, or add an AI API key for local chat.";
    }
    state = state.copyWith(messages: [
      ChatMessage(
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
      )
    ]);
  }

  /// Send a message to the chat assistant
  /// 
  /// This method handles optimistic UI updates and multi-provider AI service integration.
  /// Uses multiple AI providers (OpenAI, Anthropic, Gemini) with automatic fallback.
  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    // 1. Optimistic UI update - add user message immediately
    final userMsg = ChatMessage(
      text: trimmedText, 
      isUser: true, 
      timestamp: DateTime.now(),
    );
    
    // Add to conversation history
    _conversationHistory.add({'role': 'user', 'content': trimmedText});
    
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      // When A.U.R.A. backend (Lovable-style API) is set, send goal there first
      if (Env.isAuraBackendConfigured()) {
        final auraApi = ref.read(auraApiServiceProvider);
        final result = await auraApi.submitGoal(trimmedText);
        String responseText = result.summary;
        if (result.planDescription != null &&
            result.planDescription!.trim().isNotEmpty) {
          responseText =
              '${result.summary}\n\n${result.planDescription!.trim()}';
        }
        if (!result.success) {
          state = state.copyWith(
            messages: [
              ...state.messages,
              ChatMessage(
                text: responseText,
                isUser: false,
                timestamp: DateTime.now(),
              )
            ],
            isLoading: false,
            clearError: true,
          );
          return;
        }
        await _simulateStreamingResponse(responseText);
        if (responseText.isNotEmpty) {
          _conversationHistory.add({'role': 'assistant', 'content': responseText});
        }
        state = state.copyWith(isLoading: false, clearError: true);
        return;
      }

      // When Serverpod Aura API is configured (no AURA_BACKEND_URL), try Serverpod goal
      final serverpodAura = ref.read(serverpodAuraApiProvider);
      if (serverpodAura.isConfigured) {
        try {
          final result = await serverpodAura.submitGoal(trimmedText);
          String responseText = result.summary;
          if (result.planDescription != null &&
              result.planDescription!.trim().isNotEmpty) {
            responseText =
                '${result.summary}\n\n${result.planDescription!.trim()}';
          }
          if (!result.success) {
            state = state.copyWith(
              messages: [
                ...state.messages,
                ChatMessage(
                  text: responseText,
                  isUser: false,
                  timestamp: DateTime.now(),
                )
              ],
              isLoading: false,
              clearError: true,
            );
            return;
          }
          await _simulateStreamingResponse(responseText);
          if (responseText.isNotEmpty) {
            _conversationHistory.add({'role': 'assistant', 'content': responseText});
          }
          state = state.copyWith(isLoading: false, clearError: true);
          return;
        } catch (e) {
          debugPrint('⚠️ Serverpod Aura goal failed, falling back to AI/mock: $e');
          // Fall through to AI or mock
        }
      }

      final multiAIService = ref.read(multiAIServiceProvider);

      // Check if any AI provider is available
      if (!multiAIService.isAvailable) {
        // Fallback to mock response if no AI providers are configured
        debugPrint('⚠️ No AI providers configured, using mock response');
        final mockResponse = _generateMockResponse(trimmedText);
        await _simulateStreamingResponse(mockResponse);
        state = state.copyWith(isLoading: false, clearError: true);
        return;
      }

      // Use multi-provider AI service with streaming and automatic fallback
      String fullResponse = '';
      final agentMsg = ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(messages: [...state.messages, agentMsg]);
      
      // System prompt for Aura
      const systemPrompt = '''You are Aura, an intelligent smart home assistant. You help users control their smart home devices, answer questions about their home, and provide helpful information. Be friendly, concise, and helpful. When users ask to control devices, acknowledge their request clearly.''';
      
      // Stream AI response from multi-provider service (with automatic fallback)
      await for (final token in multiAIService.streamChatCompletion(
        messages: _conversationHistory,
        systemPrompt: systemPrompt,
        temperature: 0.7,
        maxTokens: 500,
        enableFallback: true,
      )) {
        // Check if token is an error message
        if (token.startsWith('Error:')) {
          debugPrint('❌ AI provider error: $token');
          // If we received only an error (no content yet), fall back to demo mock data
          if (fullResponse.isEmpty) {
            debugPrint('ℹ️ Falling back to demo mock response after error token');
            final mockResponse = _generateMockResponse(trimmedText);
            await _simulateStreamingResponse(mockResponse);
            state = state.copyWith(isLoading: false, clearError: true);
            return;
          }
          // If we have partial response, stop streaming and keep what we have
          break;
        }
        
        fullResponse += token;
        
        // Update the last message (Agent's message) with accumulated response
        final currentMessages = List<ChatMessage>.from(state.messages);
        if (currentMessages.isNotEmpty && !currentMessages.last.isUser) {
          currentMessages.removeLast();
        }
        
        currentMessages.add(ChatMessage(
          text: fullResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        
        state = state.copyWith(messages: currentMessages);
      }
      
      // Add assistant response to conversation history
      if (fullResponse.isNotEmpty && !fullResponse.startsWith('Error:')) {
        _conversationHistory.add({'role': 'assistant', 'content': fullResponse});
      }

      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      debugPrint('❌ Error sending chat message: $e');
      // On any unexpected error, fall back to demo mock data so the demo keeps working
      final mockResponse = _generateMockResponse(trimmedText);
      await _simulateStreamingResponse(mockResponse);
      state = state.copyWith(
        isLoading: false,
        clearError: true,
      );
    }
  }
  
  /// Simulate streaming response for better UX
  Future<void> _simulateStreamingResponse(String fullResponse) async {
    final words = fullResponse.split(' ');
    String responseText = "";
    
    // Add placeholder agent message
    final agentMsg = ChatMessage(
      text: "...",
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(messages: [...state.messages, agentMsg]);
    
    // Stream words one by one
    for (var word in words) {
      await Future.delayed(const Duration(milliseconds: 50));
      responseText = responseText.isEmpty ? word : "$responseText $word";
      
      // Update the last message (Agent's message)
      final currentMessages = List<ChatMessage>.from(state.messages);
      if (currentMessages.isNotEmpty &&
          (currentMessages.last.text == "..." ||
              currentMessages.last.text ==
                  responseText.split(' ').take(words.length - 1).join(' '))) {
        currentMessages.removeLast();
      }
      
      currentMessages.add(ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
      state = state.copyWith(messages: currentMessages);
    }
  }
  
  /// Generate mock response based on user input
  /// 
  /// This is a placeholder until Serverpod backend is connected
  String _generateMockResponse(String input) {
    final lower = input.toLowerCase();
    
    // Greetings and small talk
    if (lower.contains('hello') ||
        lower.contains('hi ') ||
        lower.startsWith('hi') ||
        lower.contains('hey') ||
        lower.contains('good morning') ||
        lower.contains('good evening')) {
      return "Hi, I'm Aura, your smart home assistant. I can help you control lights, climate, security, and more. What would you like to do?";
    }

    if (lower.contains('who are you') ||
        lower.contains('what are you') ||
        lower.contains('tell me about yourself')) {
      return "I'm Aura, a smart home AI assistant. I help you control devices, check the status of your home, and answer quick questions so your home feels effortless.";
    }

    // Lights and scenes
    if (lower.contains('turn on') ||
        lower.contains('switch on') ||
        lower.contains('lights on')) {
      return "Okay, I've turned on your lights in the requested area. You can adjust brightness or color from the Devices tab if you like.";
    }
    if (lower.contains('turn off') ||
        lower.contains('switch off') ||
        lower.contains('lights off')) {
      return "Got it, I've turned those lights off. Your energy usage just got a little better.";
    }
    if (lower.contains('dim') ||
        lower.contains('brightness') ||
        lower.contains('brighten')) {
      return "I've adjusted the brightness to a comfortable level. You can fine‑tune it in the Lights section.";
    }
    if (lower.contains('movie mode') ||
        lower.contains('scene') ||
        lower.contains('cozy') ||
        lower.contains('relax')) {
      return "Setting your home to a cozy scene: lights are warm and dim, and unnecessary devices are powered down for a relaxing atmosphere.";
    }

    // Climate / thermostat
    if (lower.contains('set') &&
        (lower.contains('temperature') ||
            lower.contains('thermostat') ||
            lower.contains('degrees'))) {
      return "I've set the thermostat to your requested temperature. It may take a few minutes for your home to adjust.";
    }
    if (lower.contains('temperature') || lower.contains('temp')) {
      return "Right now the living room is about 70°F and the bedroom is around 68°F, both within your preferred comfort range.";
    }
    if (lower.contains('heat') || lower.contains('heating')) {
      return "I've turned on the heating in your main zones. I'll keep it within your preferred schedule.";
    }
    if (lower.contains('cool') || lower.contains('air conditioning') || lower.contains('ac')) {
      return "Cooling is on. I'll bring things down gradually to avoid wasting energy.";
    }

    // Weather & time‑based info
    if (lower.contains('weather') || lower.contains('outside')) {
      return "It’s currently about 72°F outside with partly cloudy skies. It should stay mild for the next few hours—great time to air out the house.";
    }

    // Devices and status
    if (lower.contains('devices') || lower.contains('device') || lower.contains('what is on')) {
      return "You have lights, thermostats, plugs, and security sensors connected. Open the Devices tab to see everything grouped by room and status.";
    }
    if (lower.contains('status') || lower.contains('is the') && lower.contains('on')) {
      return "Most of your devices look good. Core systems are online, and a few lights are currently on in the living room.";
    }

    // Security
    if (lower.contains('lock') || lower.contains('unlock') || lower.contains('door')) {
      return "Your main doors are now secured, and I'll notify you if anything changes. You can review lock status from the Security tab.";
    }
    if (lower.contains('alarm') || lower.contains('security')) {
      return "Security is armed in home mode. Motion is monitored at the entryways while keeping indoor movement comfortable.";
    }

    // Schedules / routines
    if (lower.contains('schedule') ||
        lower.contains('routine') ||
        lower.contains('every day') ||
        lower.contains('everyday') ||
        lower.contains('at ')) {
      return "I can help you build a routine: for example, dim lights at 9pm, lock doors at 10pm, and lower the thermostat overnight. In the demo, imagine this routine is now active.";
    }

    // Energy / usage
    if (lower.contains('energy') ||
        lower.contains('power') ||
        lower.contains('usage') ||
        lower.contains('consumption')) {
      return "Your home is currently in an efficient state. Most heavy‑use devices are off, and lighting is using low‑power scenes.";
    }

    // Generic fallback for demo
    return "I'm handling your request: \"$input\" using demo smart‑home data so everything works offline. In a full setup I’ll connect to your real devices, but for now you can explore lights, climate, security, and routines as if your home were fully connected.";
  }
  
  /// Clear chat error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
  
  /// Clear all messages (useful for resetting chat)
  void clearMessages() {
    _conversationHistory.clear();
    final wasConnected = state.isConnected;
    state = ChatState(isConnected: wasConnected);
    _initialize();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
