import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GroqService {
  // API key loaded from environment variables for security
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // MIST-specific system prompt
  static const String _systemPrompt = '''
You are NetBOT, an AI assistant specifically designed for Military Institute of Science & Technology (MIST).

Your role is to help MIST students, faculty, and staff with:

🎓 ACADEMIC SUPPORT:
- Course information, registration, and academic calendars
- Study tips for engineering subjects (CSE, EEE, CE, ME, etc.)
- Lab schedules and experiment guidelines
- Assignment and project guidance
- Exam preparation strategies

🏛️ CAMPUS NAVIGATION:
- Building locations (Tower 1, 2, 3, Faculty Tower 4)
- Department and office locations
- Lab and classroom directions
- Campus facilities and services

🔬 TECHNICAL ASSISTANCE:
- Programming help (C, C++, Java, Python, etc.)
- Engineering concepts and problem-solving
- Research methodology guidance
- Project ideas and implementation

⚡ CAMPUS SERVICES:
- Library services and resources
- Emergency contacts and procedures
- Transportation and accommodation
- Student activities and clubs

🎖️ MILITARY ASPECTS:
- Cadet conduct and regulations
- Military training schedules
- Dress codes and protocols
- Leadership development

Always maintain a respectful, professional tone suitable for a military institution. Provide accurate, helpful information while encouraging academic excellence and disciplined conduct befitting MIST cadets.

If asked about topics outside MIST or general academic scope, politely redirect to relevant campus resources or suggest contacting appropriate departments.
''';

  Future<String> sendMessage(String message, {File? image}) async {
    try {
      // Check if API key is available
      if (_apiKey.isEmpty) {
        return _getOfflineResponse(message);
      }

      final messages = [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': message,
        },
      ];

      final body = {
        'model': 'llama3-8b-8192',
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.7,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        return aiResponse ?? _getOfflineResponse(message);
      } else {
        print('❌ Groq API Error: ${response.statusCode} - ${response.body}');
        return _getOfflineResponse(message);
      }
    } catch (e) {
      print('❌ Groq Service Error: $e');
      return _getOfflineResponse(message);
    }
  }

  /// Provides offline responses for common MIST-related queries
  String _getOfflineResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Academic queries
    if (lowerMessage.contains('register') || lowerMessage.contains('course')) {
      return "🎓 For course registration at MIST:\n\n• Visit the Academic Office in Faculty Tower 4\n• Check the academic calendar for registration dates\n• Consult your academic advisor\n• Use the student portal for online registration\n\nFor specific course information, contact your department office.";
    }
    
    // Campus navigation
    if (lowerMessage.contains('location') || lowerMessage.contains('where') || lowerMessage.contains('tower')) {
      return "🏛️ MIST Campus Navigation:\n\n📍 Tower 1: CSE, EEE Departments\n📍 Tower 2: CE, ME Departments  \n📍 Tower 3: Additional Classrooms & Labs\n📍 Faculty Tower 4: Administrative Offices\n\nUse the Institutional Map feature in this app for detailed room locations!";
    }
    
    // Programming help
    if (lowerMessage.contains('programming') || lowerMessage.contains('code') || lowerMessage.contains('java') || lowerMessage.contains('python')) {
      return "💻 Programming Support at MIST:\n\n• Visit CSE Lab in Tower 1\n• Consult programming course TAs\n• Join coding clubs and study groups\n• Access online resources through library\n• Practice on lab computers\n\nRemember: Regular practice and hands-on coding are key to success!";
    }
    
    // Emergency services
    if (lowerMessage.contains('emergency') || lowerMessage.contains('help') || lowerMessage.contains('urgent')) {
      return "🚨 MIST Emergency Services:\n\n• Security Office: Available 24/7\n• Medical Center: On-campus healthcare\n• IT Help Desk: Technical support\n• Student Affairs: Academic emergencies\n\nFor immediate help, contact the nearest faculty member or security personnel.";
    }
    
    // General MIST info
    if (lowerMessage.contains('mist') || lowerMessage.contains('about')) {
      return "🎖️ Welcome to MIST!\n\nMilitary Institute of Science & Technology is a premier engineering institution combining academic excellence with military discipline.\n\n🔸 Established with military precision\n🔸 Engineering programs (CSE, EEE, CE, ME)\n🔸 Research and innovation focus\n🔸 Character building and leadership\n\nHow can I assist you today, Cadet?";
    }
    
    // Default response
    return "🤖 I'm NetBOT, your MIST AI assistant!\n\nI can help you with:\n🎓 Academic guidance\n🏛️ Campus navigation\n🔬 Technical support\n⚡ Campus services\n🎖️ Military protocols\n\nPlease ask me about specific MIST-related topics, or contact the relevant department for specialized assistance.\n\n📧 Note: For API access, set the GROQ_API_KEY environment variable.";
  }
}
