import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import 'current_user_service.dart';

class AuthService {
  static final _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';

  // Global navigation key for auto-logout navigation
  static GlobalKey<NavigatorState>? navigatorKey;

  // -------------------- SIGNUP --------------------
  // Returns nothing; auto-login after signup
  static Future<void> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? designation,
  }) async {
    print('📝 Attempting signup for: $email');
    
    final body = {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      if (designation != null) 'designation': designation,
    };

    final res = await http.post(
      Uri.parse('${Config.baseUrl}/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('📡 Signup response status: ${res.statusCode}');

    if (res.statusCode == 201) {
      print('✅ Signup successful - attempting auto-login');
      // Auto-login after successful signup
      await login(email, password);
    } else {
      print('❌ Signup failed with status: ${res.statusCode}');
      print('Response body: ${res.body}');
      final err = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(err['msg'] ?? 'Signup failed (${res.statusCode})');
    }
  }

  // -------------------- LOGIN --------------------
  // Stores JWT token in secure storage
  static Future<void> login(String email, String password) async {
    print('🔐 Attempting login for: $email');
    
    final res = await http.post(
      Uri.parse('${Config.baseUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('📡 Login response status: ${res.statusCode}');
    
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
<<<<<<< HEAD
      final accessToken = body['access_token'];
      final refreshToken = body['refresh_token'];
      final expiresIn = body['expires_in'] ?? 86400; // Default to 24 hours
      
      if (accessToken != null && refreshToken != null) {
        await _storage.write(key: _tokenKey, value: accessToken);
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
        
        // Store expiry time (current time + expires_in seconds)
        final expiryTime = DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
        await _storage.write(key: _tokenExpiryKey, value: expiryTime.toString());
        
        print('✅ Login successful - tokens stored');
=======
      final token = body['access_token'];
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
        
        // Store current user info
        if (body['user'] != null) {
          final user = body['user'];
          await CurrentUserService.setCurrentUser(
            userId: user['id'],
            userName: user['name'],
            userEmail: user['email'],
          );
        } else {
          // If user info not in login response, fetch it
          await _fetchAndStoreUserInfo();
        }
>>>>>>> 26f57bf697a30ad1aec525c273be075a4fcc3fc3
      } else {
        throw Exception('Tokens missing in login response');
      }
    } else {
      print('❌ Login failed with status: ${res.statusCode}');
      print('Response body: ${res.body}');
      final err = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(err['msg'] ?? 'Login failed (${res.statusCode})');
    }
  }

  // Helper method to fetch current user info
  static Future<void> _fetchAndStoreUserInfo() async {
    try {
      final token = await getToken();
      if (token != null) {
        final url = Uri.parse('${Config.baseUrl}/api/profile');
        final res = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['user'] != null) {
            final user = body['user'];
            await CurrentUserService.setCurrentUser(
              userId: user['id'],
              userName: user['name'],
              userEmail: user['email'],
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  // -------------------- GET TOKEN --------------------
  static Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    // Check if token is expired and try to refresh
    if (await _isTokenExpired()) {
      print('🔄 Token expired, attempting refresh...');
      final refreshed = await _refreshToken();
      if (refreshed) {
        return await _storage.read(key: _tokenKey);
      } else {
        print('❌ Token refresh failed, logging out...');
        await _performAutoLogout();
        return null;
      }
    }

    return token;
  }

  // -------------------- CHECK TOKEN EXPIRY --------------------
  static Future<bool> _isTokenExpired() async {
    final expiryString = await _storage.read(key: _tokenExpiryKey);
    if (expiryString == null) return true;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
    final now = DateTime.now();
    
    // Consider token expired if it expires within next 5 minutes
    return now.isAfter(expiryTime.subtract(Duration(minutes: 5)));
  }

  // -------------------- REFRESH TOKEN --------------------
  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newAccessToken = body['access_token'];
        final expiresIn = body['expires_in'] ?? 86400;

        if (newAccessToken != null) {
          await _storage.write(key: _tokenKey, value: newAccessToken);
          
          // Update expiry time
          final expiryTime = DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
          await _storage.write(key: _tokenExpiryKey, value: expiryTime.toString());
          
          print('✅ Token refreshed successfully');
          return true;
        }
      }

      print('❌ Token refresh failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Token refresh error: $e');
      return false;
    }
  }

  // -------------------- AUTO LOGOUT --------------------
  static Future<void> _performAutoLogout() async {
    await logout();
    
    // Navigate to login page if navigator key is available
    if (navigatorKey != null && navigatorKey!.currentContext != null) {
      final context = navigatorKey!.currentContext!;
      
      // Show logout notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to login page
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  // -------------------- HANDLE HTTP ERRORS --------------------
  static Future<bool> handleHttpError(int statusCode) async {
    if (statusCode == 401) {
      print('🚫 Received 401 Unauthorized - token invalid/expired');
      await _performAutoLogout();
      return true; // Handled
    }
    return false; // Not handled
  }

  // -------------------- CHECK IF LOGGED IN --------------------
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // -------------------- GET CURRENT USER --------------------
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          return {
            'id': data['user']?['id'],
            'name': data['user']?['name'],
            'email': data['user']?['email'],
            'phone': data['user']?['phone'],
            'designation': data['user']?['designation'],
            'profile_image': data['profile']?['profile_picture'] != null 
                ? 'data:${data['profile']['profile_picture']['mime_type']};base64,${data['profile']['profile_picture']['data']}'
                : null,
            'bio': data['profile']?['bio'],
            'department': data['profile']?['department'],
            'batch': data['profile']?['batch'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // -------------------- LOGOUT --------------------
  static Future<void> logout() async {
    try {
      // Call logout endpoint on server if token is available
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        await http.post(
          Uri.parse('${Config.baseUrl}/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print('Logout endpoint error: $e');
      // Continue with local logout even if server call fails
    }

    // Clear all stored tokens
    await _storage.delete(key: _tokenKey);
<<<<<<< HEAD
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    print('🚪 Logged out - all tokens cleared');
  }

  // -------------------- SET NAVIGATOR KEY --------------------
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
=======
    await CurrentUserService.clearCurrentUser();
>>>>>>> 26f57bf697a30ad1aec525c273be075a4fcc3fc3
  }
}
