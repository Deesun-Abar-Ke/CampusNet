import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CurrentUserService {
  static int? _currentUserId;
  static String? _currentUserName;
  static String? _currentUserEmail;
  
  static const _storage = FlutterSecureStorage();
  static const String _userIdKey = 'current_user_id';
  static const String _userNameKey = 'current_user_name';
  static const String _userEmailKey = 'current_user_email';

  // Store current user info (called after login)
  static Future<void> setCurrentUser({
    required int userId,
    required String userName,
    required String userEmail,
  }) async {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserEmail = userEmail;
    
    // Persist to secure storage
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userNameKey, value: userName);
    await _storage.write(key: _userEmailKey, value: userEmail);
    
    print('DEBUG: Current user set - ID: $userId, Name: $userName');
  }

  // Load user data from storage (called on app start)
  static Future<void> loadUserFromStorage() async {
    try {
      final userIdStr = await _storage.read(key: _userIdKey);
      final userName = await _storage.read(key: _userNameKey);
      final userEmail = await _storage.read(key: _userEmailKey);
      
      if (userIdStr != null && userName != null && userEmail != null) {
        _currentUserId = int.parse(userIdStr);
        _currentUserName = userName;
        _currentUserEmail = userEmail;
        print('DEBUG: Current user loaded from storage - ID: $_currentUserId, Name: $_currentUserName');
      }
    } catch (e) {
      print('Error loading user from storage: $e');
      // Clear any partial data
      await clearCurrentUser();
    }
  }

  // Get current user ID
  static int? getCurrentUserId() {
    return _currentUserId;
  }

  // Get current user name
  static String? getCurrentUserName() {
    return _currentUserName;
  }

  // Get current user email
  static String? getCurrentUserEmail() {
    return _currentUserEmail;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return _currentUserId != null;
  }

  // Clear user data (logout)
  static Future<void> clearCurrentUser() async {
    _currentUserId = null;
    _currentUserName = null;
    _currentUserEmail = null;
    
    // Clear from secure storage
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
  }
}
