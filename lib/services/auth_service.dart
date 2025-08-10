import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'http://10.103.135.42:5000'; // your Flask backend

class AuthService {
  static final _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';

  // Signup (returns user info)
  static Future<void> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? designation,
  }) async {
    final url = Uri.parse('$baseUrl/signup');
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
      // auto-login after signup
      await login(email, password);
    } else {
      final err = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(err['msg'] ?? 'Signup failed (${res.statusCode})');
    }
  }

  // Login and store token
  static Future<void> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
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
      } else {
        throw Exception('Token missing in login response');
      }
    } else {
      final err = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(err['msg'] ?? 'Login failed (${res.statusCode})');
    }
  }

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}
