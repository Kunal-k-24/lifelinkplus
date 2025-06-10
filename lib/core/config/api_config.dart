class ApiConfig {
  static const String gptApiKey = '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';
  static const String gptBaseUrl = 'https://openrouter.ai/api/v1';
  
  // OpenRouter specific configurations
  static const Map<String, String> defaultHeaders = {
    'HTTP-Referer': 'https://github.com/your-username/lifelinkplus', // Replace with your app's URL
    'X-Title': 'LifeLink Plus First Aid Assistant',
  };
} 