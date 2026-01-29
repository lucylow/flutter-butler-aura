/// Environment configuration constants.
/// 
/// For production, use environment variables or a secure config file.
/// Never commit sensitive keys to version control.
class Env {
  // Supabase configuration
  // TODO: Move to environment variables for production
  static const String supabaseUrl = 
      String.fromEnvironment('SUPABASE_URL', 
          defaultValue: 'https://cddkoaeipwtumoqgvdfz.supabase.co');
  
  static const String supabaseAnonKey = 
      String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNkZGtvYWVpcHd0dW1vcWd2ZGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwMTcxNDIsImV4cCI6MjA4MTU5MzE0Mn0.nYsVeDQYXkTRxDYLjtmkomyi2A4kFP14PxulsFLsFXU');
  
  // Serverpod configuration
  // TODO: Configure when Serverpod server is set up
  static const String serverpodUrl = 
      String.fromEnvironment('SERVERPOD_URL',
          defaultValue: 'http://localhost:8080/');
  
  // AI API Configuration
  // Set your API keys via environment variables or compile-time constants
  // Usage: flutter run --dart-define=OPENAI_API_KEY=your_key_here --dart-define=ANTHROPIC_API_KEY=your_key_here --dart-define=GEMINI_API_KEY=your_key_here
  // Or set them directly below (not recommended for production)
  
  // OpenAI API Key
  static const String openAiApiKey = 
      String.fromEnvironment('OPENAI_API_KEY',
          defaultValue: ''); // Set your API key here or via --dart-define
  
  // Anthropic Claude API Key
  static const String anthropicApiKey = 
      String.fromEnvironment('ANTHROPIC_API_KEY',
          defaultValue: ''); // Set your API key here or via --dart-define
  
  // Google Gemini API Key
  static const String geminiApiKey = 
      String.fromEnvironment('GEMINI_API_KEY',
          defaultValue: ''); // Set your API key here or via --dart-define
  
  // Tuya Cloud (local version – used instead of Supabase for device API)
  // Usage: flutter run --dart-define=TUYA_ACCESS_ID=your_id --dart-define=TUYA_AUTH_KEY=your_key
  static const String tuyaAccessId =
      String.fromEnvironment('TUYA_ACCESS_ID', defaultValue: '');
  static const String tuyaAuthKey =
      String.fromEnvironment('TUYA_AUTH_KEY', defaultValue: '');

  /// A.U.R.A. backend (Lovable / aura-smart-home-agent API).
  /// When set, chat sends goals to POST /api/aura/goal for orchestrated device control.
  /// Example: https://your-aura-api.lovable.app or your deployed backend URL.
  static const String auraBackendUrl =
      String.fromEnvironment('AURA_BACKEND_URL', defaultValue: '');
  /// Optional JWT or API key for A.U.R.A. backend (Bearer token).
  static const String auraBackendToken =
      String.fromEnvironment('AURA_BACKEND_TOKEN', defaultValue: '');
  
  /// Validate that required environment variables are set
  /// Serverpod is optional, so it's not validated here
  static bool validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      return false;
    }
    return true;
  }

  /// Check if at least one AI provider is configured
  static bool hasAnyAIProvider() {
    return openAiApiKey.isNotEmpty || 
           anthropicApiKey.isNotEmpty || 
           geminiApiKey.isNotEmpty;
  }

  /// Check if Serverpod is configured
  static bool isServerpodConfigured() {
    return serverpodUrl.isNotEmpty && 
           serverpodUrl != 'http://localhost:8080/';
  }

  /// Check if Tuya Cloud is configured (for local version)
  static bool isTuyaConfigured() {
    return tuyaAccessId.isNotEmpty && tuyaAuthKey.isNotEmpty;
  }

  /// Check if A.U.R.A. backend (Lovable-style API) is configured
  static bool isAuraBackendConfigured() {
    final url = auraBackendUrl.trim();
    return url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
  }

  /// True when any goal backend is configured (AURA_BACKEND_URL or SERVERPOD_URL for Aura API)
  static bool isGoalBackendConfigured() {
    if (isAuraBackendConfigured()) return true;
    final url = serverpodUrl.trim();
    return url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
  }
}
