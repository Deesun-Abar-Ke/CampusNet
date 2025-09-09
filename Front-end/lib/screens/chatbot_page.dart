import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For API calls
import '../widgets/common_app_bar.dart';
import '../services/auth_service.dart';
import '../config.dart';

// A simple enum to distinguish between the user and the AI.
enum ChatUser { user, ai }

// A model class to represent a single chat message.
// (Moved to its own file or kept here for simplicity, but consider separate file)
class ChatMessage {
  final String text;
  final File? image;
  final ChatUser user;
  final String sessionId;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    this.image,
    required this.user,
    required this.sessionId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'imagePath': image?.path,
      'user': user.toString(),
      'sessionId': sessionId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      image: json['imagePath'] != null ? File(json['imagePath']) : null,
      user: ChatUser.values.firstWhere((e) => e.toString() == json['user']),
      sessionId: json['sessionId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// A model to represent a chat session
class ChatSession {
  final String id;
  final String title;
  final DateTime lastMessageTime;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessageTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lastMessageTime': lastMessageTime.toIso8601String(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
    );
  }
}

// API service for backend communication
class ChatAPI {
  static const String baseUrl = Config.baseUrl;
  
  static Future<String?> _getToken() async {
    try {
      return await AuthService.getToken();
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> createSession({String? sessionName}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': sessionName ?? 'New Chat ${DateTime.now().toString().substring(0, 16)}',
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to create session'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    required int sessionId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to send message'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSessions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get sessions'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSessionMessages(int sessionId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/sessions/$sessionId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get messages'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _speechText = '';

  final Uuid _uuid = const Uuid(); // For generating unique session IDs
  late String _currentSessionId;
  int? _currentBackendSessionId; // Backend session ID
  List<ChatSession> _sessions = []; // List of all chat sessions
  List<ChatMessage> _messages = []; // Messages for the current session
  bool _isLoadingResponse = false; // Loading state for AI responses
  bool _useOnlineMode = true; // Toggle between online/offline mode

  final List<String> _predefinedSuggestions = [
    "Tell me about MIST CSE department",
    "What are the admission requirements for MIST?",
    "Explain the campus facilities at MIST",
    "How is student life at MIST?",
    "What research opportunities are available?",
    "Tell me about MIST engineering programs",
  ];

  @override
  void initState() {
    super.initState();
    _startNewSession(); // Start a new session on app launch
    _loadSessions(); // Load existing sessions
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _startNewSession() async {
    // Generate local session ID
    final newSessionId = _uuid.v4();
    
    setState(() {
      _currentSessionId = newSessionId;
      _isLoadingResponse = false;
      _messages = [
        ChatMessage(
          text: "Hello! I'm NetBOT powered by Groq AI.\nI'm here to help you with MIST-related questions and more!",
          user: ChatUser.ai,
          sessionId: _currentSessionId,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          text: "Ask me anything about MIST academics, campus life, or general topics. I can also analyze images and process voice input!",
          user: ChatUser.ai,
          sessionId: _currentSessionId,
          timestamp: DateTime.now(),
        ),
      ];
    });

    // Create backend session if online mode is enabled
    if (_useOnlineMode) {
      try {
        final result = await ChatAPI.createSession(
          sessionName: "New Chat ${DateFormat('MMM d, hh:mm a').format(DateTime.now())}",
        );
        
        if (result['success']) {
          final sessionData = result['data']['session'];
          _currentBackendSessionId = sessionData['id'];
          print('Backend session created: $_currentBackendSessionId');
        } else {
          print('Failed to create backend session: ${result['error']}');
          // Continue with local-only mode
          _useOnlineMode = false;
        }
      } catch (e) {
        print('Error creating backend session: $e');
        _useOnlineMode = false;
      }
    }

    // Save initial messages but don't create session entry yet
    // Session will be created when user sends their first message
    _saveMessages(); // Save initial messages
    _scrollToBottom();
  }

  Future<void> _loadSessions() async {
    print('📂 Loading chat sessions...');
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString('chat_sessions');
    
    print('📄 Sessions JSON found: ${sessionsJson != null}');
    if (sessionsJson != null) {
      print('📊 JSON content: $sessionsJson');
      try {
        Iterable decoded = jsonDecode(sessionsJson);
        setState(() {
          _sessions = decoded.map((s) => ChatSession.fromJson(s)).toList();
          // Sort sessions by last message time, newest first
          _sessions.sort(
            (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
          );
        });
        print('✅ Loaded ${_sessions.length} sessions');
      } catch (e) {
        print('❌ Error loading sessions: $e');
        setState(() {
          _sessions = [];
        });
      }
    } else {
      print('📭 No sessions found');
      setState(() {
        _sessions = [];
      });
    }
  }

  Future<void> _saveSessions() async {
    print('💾 Saving ${_sessions.length} sessions...');
    final prefs = await SharedPreferences.getInstance();
    final String sessionsJson = jsonEncode(
      _sessions.map((s) => s.toJson()).toList(),
    );
    await prefs.setString('chat_sessions', sessionsJson);
    print('✅ Sessions saved successfully');
    
    // Debug: Print session titles
    for (int i = 0; i < _sessions.length; i++) {
      print('   Session $i: ${_sessions[i].title} (${_sessions[i].id})');
    }
  }

  Future<void> _loadMessages(String sessionId) async {
    print('🔍 Loading messages for session: $sessionId');
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson = prefs.getString('session_$sessionId');
    
    print('📄 Messages JSON found: ${messagesJson != null}');
    if (messagesJson != null) {
      print('📊 JSON length: ${messagesJson.length}');
    }
    
    setState(() {
      if (messagesJson != null) {
        try {
          Iterable decoded = jsonDecode(messagesJson);
          _messages = decoded.map((m) => ChatMessage.fromJson(m)).toList();
          print('✅ Loaded ${_messages.length} messages');
        } catch (e) {
          print('❌ Error loading messages: $e');
          _messages = [];
        }
      } else {
        _messages = []; // No messages for this session yet
        print('📭 No messages found for this session');
      }
      _currentSessionId = sessionId; // Set current session
    });
    _scrollToBottom();
  }

  Future<void> _saveMessages() async {
    print('💾 Saving ${_messages.length} messages for session: $_currentSessionId');
    final prefs = await SharedPreferences.getInstance();
    final String messagesJson = jsonEncode(
      _messages.map((m) => m.toJson()).toList(),
    );
    await prefs.setString('session_$_currentSessionId', messagesJson);
    print('✅ Messages saved successfully');
  }

  String _generateSessionTitle() {
    // Find the first user message (skip AI welcome messages)
    for (ChatMessage message in _messages) {
      if (message.user == ChatUser.user && message.text.trim().isNotEmpty) {
        String title = message.text.split('\n').first.trim();
        // Limit title length for better display
        if (title.length > 30) {
          title = title.substring(0, 30) + '...';
        }
        return title;
      }
    }
    // Fallback title if no user message found
    return 'Chat Session ${DateTime.now().toString().substring(11, 16)}'; // HH:MM format
  }

  bool _hasUserMessages() {
    return _messages.any((message) => message.user == ChatUser.user);
  }

  void _updateSessionList(ChatSession newSession) {
    print('🔄 Updating session list with: ${newSession.id} - ${newSession.title}');
    int existingIndex = _sessions.indexWhere((s) => s.id == newSession.id);
    if (existingIndex != -1) {
      // Update existing session
      print('✏️ Updating existing session at index $existingIndex');
      _sessions[existingIndex] = newSession;
    } else {
      // Add new session
      print('➕ Adding new session');
      _sessions.add(newSession);
    }
    // Sort sessions again to keep newest at top
    _sessions.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    print('📋 Total sessions: ${_sessions.length}');
  }

  void _sendMessage({String? text, File? image}) async {
    String messageText = text ?? _textController.text;

    if (messageText.trim().isNotEmpty || image != null) {
      final newMessage = ChatMessage(
        text: messageText,
        image: image,
        user: ChatUser.user,
        sessionId: _currentSessionId,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(newMessage);
        _isLoadingResponse = true; // Show loading indicator
      });

      // Clear the text field if the message came from it
      if (text == null) {
        _textController.clear();
      }

      _scrollToBottom();
      _saveMessages(); // Save user message

      // Update current session's last message time
      _updateSessionList(
        ChatSession(
          id: _currentSessionId,
          title: _messages.first.text.split('\n').first, // Use first message as title
          lastMessageTime: newMessage.timestamp,
        ),
      );
      _saveSessions();

      // --- Get AI Response from Backend ---
      String aiResponseText = "I'm experiencing technical difficulties. Please try again in a moment.";
      
      if (_useOnlineMode && _currentBackendSessionId != null) {
        try {
          // Prepare message for API (handle image if present)
          String apiMessage = messageText;
          if (image != null) {
            apiMessage = "$messageText [Image attached: ${image.path.split('/').last}]";
          }

          final result = await ChatAPI.sendMessage(
            message: apiMessage,
            sessionId: _currentBackendSessionId!,
          );

          if (result['success']) {
            final messageData = result['data']['message'];
            aiResponseText = messageData['ai_response'] ?? 'No response received.';
          } else {
            aiResponseText = "Sorry, I encountered an error: ${result['error']}";
            // Fallback to offline mode if API fails
            if (result['error'].toString().contains('Network')) {
              _useOnlineMode = false;
              aiResponseText = "I'm currently offline. Your message has been saved locally.";
            }
          }
        } catch (e) {
          print('API Error: $e');
          aiResponseText = "I'm having trouble connecting to my brain right now. Let me think locally...";
          _useOnlineMode = false;
        }
      } else {
        // Offline mode - provide a simple response
        aiResponseText = _generateOfflineResponse(messageText);
      }

      // Add AI response with a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      final aiResponse = ChatMessage(
        text: aiResponseText,
        user: ChatUser.ai,
        sessionId: _currentSessionId,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(aiResponse);
        _isLoadingResponse = false; // Hide loading indicator
      });
      
      _scrollToBottom();
      _saveMessages(); // Save AI response

      // Only create/update session if there are actual user messages
      if (_hasUserMessages()) {
        _updateSessionList(
          ChatSession(
            id: _currentSessionId,
            title: _generateSessionTitle(),
            lastMessageTime: aiResponse.timestamp,
          ),
        );
        _saveSessions();
      }
    }
  }

  String _generateOfflineResponse(String message) {
    // Simple offline responses based on keywords
    final lowercaseMessage = message.toLowerCase();
    
    if (lowercaseMessage.contains('mist') || lowercaseMessage.contains('university')) {
      return "MIST (Military Institute of Science and Technology) is a prestigious engineering university in Bangladesh. I'm currently offline, but I'd love to tell you more when I'm back online!";
    } else if (lowercaseMessage.contains('hello') || lowercaseMessage.contains('hi')) {
      return "Hello! I'm NetBOT. I'm currently running in offline mode, but I can still chat with you. For detailed information about MIST, please try again when I'm online.";
    } else if (lowercaseMessage.contains('help')) {
      return "I'm here to help! Currently running offline, so my responses are limited. When online, I can help with MIST academics, campus info, general questions, image analysis, and more.";
    } else {
      return "Thanks for your message! I'm currently offline, so I can't provide my usual detailed responses. Please try again later for full AI-powered assistance with MIST and other topics.";
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        _sendMessage(
          text:
              "Here's an image from my ${source == ImageSource.camera ? 'camera' : 'gallery'}.",
          image: File(image.path),
        );
      }
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Permission to access ${source == ImageSource.camera ? 'camera' : 'gallery'} was denied.",
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Permission to access ${source == ImageSource.camera ? 'camera' : 'gallery'} permanently denied. Please enable from settings.",
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _recordVoice() async {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
        if (_speechText.isNotEmpty) {
          _sendMessage(text: _speechText);
        }
        _speechText = '';
      });
    } else {
      PermissionStatus status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize(
          onStatus: (status) {
            print('Speech recognition status: $status');
            if (status == 'notListening' && _isListening) {
              setState(() {
                _isListening = false;
                if (_speechText.isNotEmpty) {
                  _sendMessage(text: _speechText);
                }
                _speechText = '';
              });
            }
          },
          onError: (errorNotification) {
            print('Speech recognition error: ${errorNotification.errorMsg}');
            setState(() {
              _isListening = false;
              _speechText = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Voice input error: ${errorNotification.errorMsg}",
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );

        if (available) {
          setState(() {
            _isListening = true;
            _speechText = '';
            _textController
                .clear(); // Clear text field when starting voice input
          });
          _speech.listen(
            onResult: (result) {
              setState(() {
                _speechText = result.recognizedWords;
                _textController.text =
                    _speechText; // Update text field in real-time
              });
            },
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Listening... Speak now!"),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Speech recognition not available."),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Permission to access microphone was denied."),
            duration: Duration(seconds: 3),
          ),
        );
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Permission to access microphone permanently denied. Please enable from settings.",
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2F33), // Dark theme background
      appBar: CommonAppBar(
        title: Row(
          children: [
            const Text(
              "NetBOT",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _useOnlineMode ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _useOnlineMode ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        showBackButton: true,
        centerTitle: false,
        elevation: 4,
        backgroundColor: const Color(0xFF23272A), // Darker app bar
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_useOnlineMode ? Icons.wifi : Icons.wifi_off),
            tooltip: _useOnlineMode ? 'Online Mode' : 'Offline Mode',
            onPressed: () {
              setState(() {
                _useOnlineMode = !_useOnlineMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_useOnlineMode 
                    ? 'Switched to Online Mode - Full AI features available' 
                    : 'Switched to Offline Mode - Limited responses only'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () {
              _showChatHistoryDrawer(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: _startNewSession,
          ),
        ],
      ),
      body: Column(
        children: [
          // Predefined suggestions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _predefinedSuggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(
                        suggestion,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      backgroundColor: const Color(
                        0xFF424549,
                      ), // Darker chip background
                      onPressed: () {
                        _textController.text = suggestion;
                        _sendMessage();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length + (_isLoadingResponse ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoadingResponse) {
                  // Show loading indicator at the end
                  return const ChatLoadingIndicator();
                }
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  void _showChatHistoryDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8, // Initial height of the sheet
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false, // Don't expand to full height immediately
          builder: (_, scrollController) {
            return Container(
              color: const Color(0xFF23272A), // Drawer background
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Chat History',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    child: _sessions.isEmpty
                        ? Center(
                            child: Text(
                              "No chat sessions yet.",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              return Card(
                                color: const Color(
                                  0xFF2C2F33,
                                ), // Card background
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 4.0,
                                ),
                                elevation: 2,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.blueAccent,
                                  ),
                                  title: Text(
                                    session.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    DateFormat(
                                      'MMM d, yyyy hh:mm a',
                                    ).format(session.lastMessageTime),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                    ); // Close the bottom sheet
                                    _loadMessages(session.id);
                                  },
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Chat?'),
                                          content: const Text(
                                            'Are you sure you want to delete this chat history?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        _deleteSession(session.id);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_$sessionId'); // Delete messages for the session
    setState(() {
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) {
        _startNewSession(); // Start a new session if the current one was deleted
      }
      _saveSessions(); // Save updated session list
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat session deleted.')));
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Color(0xFF23272A), // Darker input background
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Color(0xFF99AAB5),
              ), // Lighter icon color
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Container(
                        color: const Color(
                          0xFF2C2F33,
                        ), // Bottom sheet background
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(
                                Icons.camera_alt,
                                color: Colors.white70,
                              ),
                              title: const Text(
                                'Take Photo',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.photo_library,
                                color: Colors.white70,
                              ),
                              title: const Text(
                                'Choose from Gallery',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              tooltip: 'Attach Image',
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF424549), // Input field background
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(
                    color: Colors.white,
                  ), // Text input color
                  decoration: const InputDecoration(
                    hintText: "Ask NetBOT...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, child) {
                if (value.text.trim().isEmpty && !_isListening) {
                  return CircleAvatar(
                    backgroundColor: const Color(0xFF7289DA), // AI-themed blue
                    child: IconButton(
                      icon: const Icon(Icons.mic, color: Colors.white),
                      onPressed: _recordVoice,
                      tooltip: 'Voice Input',
                    ),
                  );
                } else if (_isListening) {
                  return CircleAvatar(
                    backgroundColor: Colors.redAccent, // Indicate recording
                    child: IconButton(
                      icon: const Icon(Icons.stop, color: Colors.white),
                      onPressed: _recordVoice,
                      tooltip: 'Stop Recording',
                    ),
                  );
                } else {
                  return CircleAvatar(
                    backgroundColor: const Color(0xFF7289DA), // AI-themed blue
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                      tooltip: 'Send Message',
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// A widget to display a single chat message bubble.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment = message.user == ChatUser.user
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    final bubbleColor = message.user == ChatUser.user
        ? const Color(0xFF7289DA) // AI-themed blue for user
        : const Color(0xFF424549); // Darker grey for AI

    final textColor =
        Colors.white; // White for both for better contrast on dark background

    final borderRadius = message.user == ChatUser.user
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
              ),
              if (message.image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(message.image!),
                  ),
                ),
              // Optional: Display timestamp for each message
              Padding(
                padding: EdgeInsets.only(
                  top: message.image != null ? 8.0 : 4.0,
                ),
                child: Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Loading indicator for AI responses
class ChatLoadingIndicator extends StatefulWidget {
  const ChatLoadingIndicator({super.key});

  @override
  State<ChatLoadingIndicator> createState() => _ChatLoadingIndicatorState();
}

class _ChatLoadingIndicatorState extends State<ChatLoadingIndicator> 
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF424549),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                topLeft: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NetBOT is thinking',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Opacity(
                            opacity: ((_controller.value * 3 - index) % 3) < 1 ? 
                              ((_controller.value * 3 - index) % 3) : 0.3,
                            child: const Text(
                              '●',
                              style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
