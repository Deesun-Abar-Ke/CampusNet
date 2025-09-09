class Config {
  // Base URL for the Flask backend
  static const String baseUrl = 'http://192.168.0.105:5000';
  
  // API endpoints
  static const String authEndpoint = '/api/auth';
  static const String chatEndpoint = '/api/chat';
  static const String usersEndpoint = '/api/users';
  
  // File size limits (in bytes)
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Supported file types for upload
  static const List<String> supportedImageTypes = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'
  ];
  
  static const List<String> supportedDocumentTypes = [
    '.pdf', '.txt', '.doc', '.docx'
  ];
  
  static const List<String> supportedAudioTypes = [
    '.mp3', '.wav', '.m4a', '.aac'
  ];
  
  // Chat settings
  static const int maxMessageLength = 5000;
  static const int maxSessionsPerUser = 50;
  
  // App settings
  static const String appName = 'CampusNet AI Chat';
  static const String version = '1.0.0';
  
  // Colors (matching MIST theme)
  static const mistBlue = 0xFF1976D2;
  static const mistGreen = 0xFF388E3C;
  static const mistRed = 0xFFD32F2F;
  static const mistGray = 0xFF757575;
  
  // Get all supported file types
  static List<String> get allSupportedTypes {
    return [
      ...supportedImageTypes,
      ...supportedDocumentTypes,
      ...supportedAudioTypes,
    ];
  }
  
  // Check if file type is supported
  static bool isFileTypeSupported(String fileName) {
    final extension = fileName.toLowerCase();
    return allSupportedTypes.any((type) => extension.endsWith(type));
  }
  
  // Get file type category
  static String getFileTypeCategory(String fileName) {
    final extension = fileName.toLowerCase();
    
    if (supportedImageTypes.any((type) => extension.endsWith(type))) {
      return 'image';
    } else if (supportedDocumentTypes.any((type) => extension.endsWith(type))) {
      return 'document';
    } else if (supportedAudioTypes.any((type) => extension.endsWith(type))) {
      return 'audio';
    }
    
    return 'unknown';
  }
}
