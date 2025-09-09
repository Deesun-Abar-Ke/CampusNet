class CurrentUserService {
  static int? _currentUserId;
  static String? _currentUserName;
  static String? _currentUserEmail;

  // Store current user info (called after login)
  static void setCurrentUser({
    required int userId,
    required String userName,
    required String userEmail,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserEmail = userEmail;
    print('DEBUG: Current user set - ID: $userId, Name: $userName');
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
  static void clearCurrentUser() {
    _currentUserId = null;
    _currentUserName = null;
    _currentUserEmail = null;
  }
}
