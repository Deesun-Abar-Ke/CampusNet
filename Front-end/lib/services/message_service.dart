import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class MessageService {
  static const String baseUrl = Config.baseUrl;
  
  // Get authentication token
  Future<String?> _getToken() async {
    return await AuthService.getToken();
  }

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all conversations for the current user
  Future<Map<String, dynamic>> getConversations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/conversations'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'conversations': data['conversations'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch conversations',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Create a new conversation
  Future<Map<String, dynamic>> createConversation({
    required String type, // 'individual' or 'group'
    required List<int> participantIds,
    String? name,
    String? avatar,
    String? courseFolder,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'type': type,
        'participant_ids': participantIds,
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (courseFolder != null) 'course_folder': courseFolder,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/messages/conversations'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'conversation': data['conversation'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get messages for a specific conversation
  Future<Map<String, dynamic>> getMessages(int conversationId, {int page = 1, int perPage = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/conversations/$conversationId/messages?page=$page&per_page=$perPage'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'messages': data['messages'] ?? [],
          'has_more': data['has_more'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch messages',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send a message
  Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? referenceData,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'content': content,
        'message_type': messageType,
        if (referenceData != null) 'reference_data': referenceData,
      };

      print('DEBUG - MessageService sending payload: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/messages/conversations/$conversationId/messages'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Search users
  Future<Map<String, dynamic>> searchUsers({
    String? query,
    String? department,
    String? level,
    String? session,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      
      if (query != null && query.isNotEmpty) queryParams['query'] = query;
      if (department != null && department != 'all') queryParams['department'] = department;
      if (level != null && level != 'all') queryParams['level'] = level;
      if (session != null && session != 'all') queryParams['session'] = session;

      final uri = Uri.parse('$baseUrl/api/messages/users/search').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'users': data['users'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to search users',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Add participants to a conversation
  Future<Map<String, dynamic>> addParticipants(int conversationId, List<int> userIds) async {
    try {
      final headers = await _getHeaders();
      final body = {'user_ids': userIds};

      final response = await http.post(
        Uri.parse('$baseUrl/api/messages/conversations/$conversationId/participants'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'added_users': data['added_users'] ?? [],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add participants',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Remove participant from conversation
  Future<Map<String, dynamic>> removeParticipant(int conversationId, int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/messages/conversations/$conversationId/participants/$userId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to remove participant',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get conversation participants
  Future<Map<String, dynamic>> getParticipants(int conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/conversations/$conversationId/participants'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'participants': data['participants'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch participants',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark message as read
  Future<Map<String, dynamic>> markMessageRead(int messageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages/messages/$messageId/read'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to mark message as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get conversation participants
  Future<Map<String, dynamic>> getConversationParticipants(int conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/messages/conversations/$conversationId/participants'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'participants': data['participants'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load participants',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Upload file and return file information
  Future<Map<String, dynamic>> uploadFile(String? filePath, String fileName, {List<int>? fileBytes}) async {
    try {
      final uri = Uri.parse('${Config.baseUrl}/api/messages/upload');
      final token = await _getToken();
      
      var request = http.MultipartRequest('POST', uri);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add file to request - handle both mobile (path) and web (bytes)
      if (fileBytes != null) {
        // Web platform - use bytes
        var file = http.MultipartFile.fromBytes('file', fileBytes, filename: fileName);
        request.files.add(file);
      } else if (filePath != null) {
        // Mobile platform - use path
        var file = await http.MultipartFile.fromPath('file', filePath, filename: fileName);
        request.files.add(file);
      } else {
        return {
          'success': false,
          'message': 'No file data provided',
        };
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'file_url': data['file_url'],
          'file_name': data['file_name'],
          'file_type': data['file_type'],
          'file_size': data['file_size'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload file',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send file message
  Future<Map<String, dynamic>> sendFileMessage({
    required int conversationId,
    required String fileUrl,
    required String fileName,
    required String fileType,
    String? caption,
  }) async {
    try {
      final uri = Uri.parse('${Config.baseUrl}/api/messages/conversations/$conversationId/messages');
      final headers = await _getHeaders();
      
      final body = {
        'content': caption ?? fileName,
        'message_type': fileType == 'image' ? 'image' : 'file',
        'file_url': fileUrl,
        'file_name': fileName,
        'file_type': fileType,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send file message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
