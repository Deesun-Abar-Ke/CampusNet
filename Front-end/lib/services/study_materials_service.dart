import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';

class StudyMaterialsService {
  // ------------------ DEPARTMENTS ------------------

  static Future<List<dynamic>> fetchDepartments() async {
    final url = Uri.parse('$baseUrl/departments');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load departments');
    }
  }

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

  static Future<List<dynamic>> fetchCourses(int departmentId) async {
    final url = Uri.parse('$baseUrl/courses?department_id=$departmentId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load courses');
    }
  }

  static Future<void> addCourse({
    required String name,
    required int departmentId,
  }) async {
    final url = Uri.parse('$baseUrl/courses');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'name': name, 'department_id': departmentId});

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = _extractErrorMessage(res.body);
      throw Exception('Failed to add course: $msg');
    }
  }

  // ------------------ NOTES ------------------

  static Future<List<dynamic>> fetchNotes(int courseId) async {
    final url = Uri.parse('$baseUrl/notes?course_id=$courseId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final notes = jsonDecode(res.body) as List<dynamic>;

      // Ensure each note has a file_url, default if missing
      for (var note in notes) {
        if (note['file_url'] == null || note['file_url'].toString().isEmpty) {
          note['file_url'] = '/study/notes/default';
        }
      }

      return notes;
    } else {
      throw Exception('Failed to load notes');
    }
  }

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
      'file_url': fileUrl.isNotEmpty ? fileUrl : '/study/notes/default',
      'file_type': fileType,
      'course_id': courseId,
    });

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = _extractErrorMessage(res.body);
      throw Exception('Failed to upload note: $msg');
    }
  }

  // ------------------ HELPER ------------------

  static String _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      return decoded['msg']?.toString() ?? responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
