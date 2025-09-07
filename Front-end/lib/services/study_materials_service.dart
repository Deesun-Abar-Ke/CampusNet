import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';

class StudyMaterialsService {
  // ------------------ DEPARTMENTS ------------------

  // Fetch all departments
  static Future<List<dynamic>> fetchDepartments() async {
    final url = Uri.parse('$baseUrl/departments');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load departments');
    }
  }

  // Add a new department
  static Future<void> addDepartment(String name, String icon) async {
    final url = Uri.parse('$baseUrl/departments');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'name': name, 'icon': icon});

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = _extractErrorMessage(res.body);
      throw Exception('Failed to add department: $msg');
    }
  }

  // ------------------ COURSES ------------------

  // Fetch courses by department ID
  static Future<List<dynamic>> fetchCourses(int departmentId) async {
    final url = Uri.parse('$baseUrl/courses?department_id=$departmentId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load courses');
    }
  }

  // Add a new course
  static Future<void> addCourse({
    required String name,
    required int departmentId,
  }) async {
    final url = Uri.parse('$baseUrl/courses');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'name': name,
      'department_id': departmentId, // 👈 keep consistent with backend
    });

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = _extractErrorMessage(res.body);
      throw Exception('Failed to add course: $msg');
    }
  }

  // ------------------ NOTES ------------------

  // Fetch notes by course ID
  static Future<List<dynamic>> fetchNotes(int courseId) async {
    final url = Uri.parse('$baseUrl/notes?course_id=$courseId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load notes');
    }
  }

  // Upload a new note (requires JWT auth)
  static Future<void> uploadNote({
    required String filename,
    required String fileUrl,
    required String fileType,
    required int courseId,
  }) async {
    final url = Uri.parse('$baseUrl/notes');
    final token = await AuthService.getToken();

    if (token == null) throw Exception('Not authenticated');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'filename': filename,
      'file_url': fileUrl,
      'file_type': fileType,
      'course_id': courseId,
    });

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = _extractErrorMessage(res.body);
      throw Exception('Failed to upload note: $msg');
    }
  }

  // ------------------ Helper ------------------

  static String _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      return decoded['msg']?.toString() ?? responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
