import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import 'current_user_service.dart';

class AuthService {
  static final _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';

  // -------------------- SIGNUP --------------------
  // Returns nothing; auto-login after signup
  static Future<void> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? designation,
  }) async {
    final url = Uri.parse('${Config.baseUrl}/signup');
    final body = {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      if (designation != null) 'designation': designation,
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) {
      // Auto-login after successful signup
      await login(email, password);
    } else {
      final err = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(err['msg'] ?? 'Signup failed (${res.statusCode})');
    }
  }

  // -------------------- LOGIN --------------------
  // Stores JWT token in secure storage
  static Future<void> login(String email, String password) async {
    final url = Uri.parse('${Config.baseUrl}/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final token = body['access_token'];
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
        
        // Store current user info
        if (body['user'] != null) {
          final user = body['user'];
          CurrentUserService.setCurrentUser(
            userId: user['id'],
            userName: user['name'],
            userEmail: user['email'],
          );
        } else {
          // If user info not in login response, fetch it
          await _fetchAndStoreUserInfo();
        }
      } else {
        throw Exception('Token missing in login response');
      }
    } else {
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
            CurrentUserService.setCurrentUser(
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
    return await _storage.read(key: _tokenKey);
  }

  // -------------------- LOGOUT --------------------
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    CurrentUserService.clearCurrentUser();
  }
}
