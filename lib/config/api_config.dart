class ApiConfig {
  // Environment variable for Groq API key (secure approach)
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '', // Empty default - will need to be set via environment or build args
  );
  
  // Groq API endpoints
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama3-8b-8192'; // Fast 8B parameter model with 8192 context
  
  // Validation helper
  static bool get isApiKeyConfigured => groqApiKey.isNotEmpty;
}
