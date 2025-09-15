import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user profile: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> getAchievements(String token) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/achievements');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['achievements'] ?? [];
    } else {
      throw Exception('Failed to get achievements: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> getSkills(String token) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/skills');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['skills'] ?? [];
    } else {
      throw Exception('Failed to get skills: ${response.statusCode}');
    }
  }

  static Future<Uint8List> generateCV(String token) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/cv');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to generate CV: ${response.statusCode}');
    }
  }

  static Future<bool> addAchievement(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/achievements');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> updateAchievement(String token, int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/achievements/$id');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteAchievement(String token, int id) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/achievements/$id');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  static Future<bool> addSkill(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/skills');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> updateSkill(String token, int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/skills/$id');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteSkill(String token, int id) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/skills/$id');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  static Future<bool> updateProfile(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  static Future<bool> uploadProfilePicture(String token, Uint8List imageBytes, String filename) async {
    final url = Uri.parse('${Config.baseUrl}/api/profile/picture');
    final request = http.MultipartRequest('POST', url);
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'picture', 
      imageBytes,
      filename: filename,
    ));

    final response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
