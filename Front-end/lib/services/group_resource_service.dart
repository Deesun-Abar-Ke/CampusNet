// lib/services/group_resource_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class GroupResourceService {
  static const String baseUrl = '${Config.baseUrl}/api';

  // Helper to get headers with JWT authorization
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    print('DEBUG - GroupResourceService: Token retrieved: ${token != null ? "YES (${token.length} chars)" : "NO"}');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper to get headers for file upload (multipart)
  static Future<Map<String, String>> _getFileHeaders() async {
    final token = await AuthService.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get folders and files for a conversation
  static Future<Map<String, dynamic>> getFolders(int conversationId, {int? parentFolderId}) async {
    try {
      String url = '$baseUrl/conversations/$conversationId/folders';
      if (parentFolderId != null) {
        url += '?parent_folder_id=$parentFolderId';
      } else {
        url += '?parent_folder_id=null';
      }

      final headers = await _getHeaders();
      print('DEBUG - GroupResourceService: Making request to $url');
      print('DEBUG - GroupResourceService: Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('DEBUG - GroupResourceService: Response status: ${response.statusCode}');
      print('DEBUG - GroupResourceService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else if (response.statusCode == 404) {
        throw Exception('Conversation not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to load resources');
      }
    } catch (e) {
      print('Error getting folders: $e');
      rethrow;
    }
  }

  // Create a new folder
  static Future<Map<String, dynamic>> createFolder(
    int conversationId, 
    String name, 
    {int? parentFolderId, String? description}
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/folders'),
        headers: headers,
        body: json.encode({
          'name': name,
          'parent_folder_id': parentFolderId,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else if (response.statusCode == 409) {
        throw Exception('Folder with this name already exists');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create folder');
      }
    } catch (e) {
      print('Error creating folder: $e');
      rethrow;
    }
  }

  // Upload file to folder
  static Future<Map<String, dynamic>> uploadFile(
    int conversationId,
    int folderId,
    File file,
    {String? description}
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/conversations/$conversationId/folders/$folderId/upload'),
      );

      // Add headers
      request.headers.addAll(await _getFileHeaders());

      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Add description if provided
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else if (response.statusCode == 404) {
        throw Exception('Folder not found');
      } else if (response.statusCode == 409) {
        throw Exception('File with this name already exists in folder');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to upload file');
      }
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // Delete folder
  static Future<void> deleteFolder(int conversationId, int folderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/conversations/$conversationId/folders/$folderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Admin access required');
      } else if (response.statusCode == 404) {
        throw Exception('Folder not found');
      } else if (response.statusCode == 409) {
        throw Exception('Cannot delete non-empty folder');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete folder');
      }
    } catch (e) {
      print('Error deleting folder: $e');
      rethrow;
    }
  }

  // Delete file
  static Future<void> deleteFile(int conversationId, int fileId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/conversations/$conversationId/files/$fileId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else if (response.statusCode == 404) {
        throw Exception('File not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete file');
      }
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  // Get folder path (breadcrumb)
  static Future<List<Map<String, dynamic>>> getFolderPath(int conversationId, int folderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId/folders/$folderId/path'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['path'] ?? []);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get folder path');
      }
    } catch (e) {
      print('Error getting folder path: $e');
      rethrow;
    }
  }

  // Search resources
  static Future<Map<String, dynamic>> searchResources(int conversationId, String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Search failed');
      }
    } catch (e) {
      print('Error searching resources: $e');
      rethrow;
    }
  }

  // Get file download URL
  static String getFileDownloadUrl(String filename) {
    return '$baseUrl/files/$filename';
  }

  // Download file
  static Future<void> downloadFile(String filename, String originalFilename) async {
    try {
      final headers = await _getFileHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/files/$filename'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Handle file download - this would need platform-specific implementation
        // For now, we'll just return success
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else if (response.statusCode == 404) {
        throw Exception('File not found');
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }
}
