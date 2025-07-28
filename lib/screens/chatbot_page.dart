import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert'; // For JSON encoding/decoding

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
  List<ChatSession> _sessions = []; // List of all chat sessions
  List<ChatMessage> _messages = []; // Messages for the current session

  final List<String> _predefinedSuggestions = [
    "Summarize this document for me.",
    "Explain quantum physics in simple terms.",
    "Write a short story about a talking cat.",
    "Give me some ideas for a healthy dinner.",
    "What's the weather like in Dhaka?",
    "Help me brainstorm ideas for a new app.",
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

  void _startNewSession() {
    setState(() {
      _currentSessionId = _uuid.v4(); // Generate a new unique ID for the session
      _messages = [
        ChatMessage(
          text: "Hello, Boss!\nI'm NetBOT, ready to help you!",
          user: ChatUser.ai,
          sessionId: _currentSessionId,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          text: "Ask me anything that's on your mind. I'm here to assist you!",
          user: ChatUser.ai,
          sessionId: _currentSessionId,
          timestamp: DateTime.now(),
        ),
      ];
      // Add or update the current session in the list
      _updateSessionList(ChatSession(
        id: _currentSessionId,
        title: "New Chat ${DateFormat('MMM d, hh:mm a').format(DateTime.now())}",
        lastMessageTime: DateTime.now(),
      ));
      _saveMessages(); // Save initial messages
      _saveSessions(); // Save updated session list
    });
    _scrollToBottom();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString('chat_sessions');
    if (sessionsJson != null) {
      Iterable decoded = jsonDecode(sessionsJson);
      setState(() {
        _sessions = decoded.map((s) => ChatSession.fromJson(s)).toList();
        // Sort sessions by last message time, newest first
        _sessions.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      });
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String sessionsJson = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString('chat_sessions', sessionsJson);
  }

  Future<void> _loadMessages(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson = prefs.getString('session_$sessionId');
    setState(() {
      if (messagesJson != null) {
        Iterable decoded = jsonDecode(messagesJson);
        _messages = decoded.map((m) => ChatMessage.fromJson(m)).toList();
      } else {
        _messages = []; // No messages for this session yet
      }
      _currentSessionId = sessionId; // Set current session
    });
    _scrollToBottom();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String messagesJson = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString('session_$_currentSessionId', messagesJson);
  }

  void _updateSessionList(ChatSession newSession) {
    int existingIndex = _sessions.indexWhere((s) => s.id == newSession.id);
    if (existingIndex != -1) {
      // Update existing session
      _sessions[existingIndex] = newSession;
    } else {
      // Add new session
      _sessions.add(newSession);
    }
    // Sort sessions again to keep newest at top
    _sessions.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }

  void _sendMessage({String? text, File? image}) {
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
      });

      // Clear the text field if the message came from it
      if (text == null) {
        _textController.clear();
      }

      _scrollToBottom();
      _saveMessages(); // Save user message

      // Update current session's last message time
      _updateSessionList(ChatSession(
        id: _currentSessionId,
        title: _messages.first.text.split('\n').first, // Use first message as title
        lastMessageTime: newMessage.timestamp,
      ));
      _saveSessions();

      // --- AI Response Simulation ---
      Future.delayed(const Duration(milliseconds: 800), () {
        final aiResponse = ChatMessage(
          text: "Understood! I'm processing your request now. How else can I help?",
          user: ChatUser.ai,
          sessionId: _currentSessionId,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(aiResponse);
        });
        _scrollToBottom();
        _saveMessages(); // Save AI response

        _updateSessionList(ChatSession(
          id: _currentSessionId,
          title: _messages.first.text.split('\n').first,
          lastMessageTime: aiResponse.timestamp,
        ));
        _saveSessions();
      });
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
          text: "Here's an image from my ${source == ImageSource.camera ? 'camera' : 'gallery'}.",
          image: File(image.path),
        );
      }
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Permission to access ${source == ImageSource.camera ? 'camera' : 'gallery'} was denied."),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Permission to access ${source == ImageSource.camera ? 'camera' : 'gallery'} permanently denied. Please enable from settings."),
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
                content: Text("Voice input error: ${errorNotification.errorMsg}"),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );

        if (available) {
          setState(() {
            _isListening = true;
            _speechText = '';
            _textController.clear(); // Clear text field when starting voice input
          });
          _speech.listen(
            onResult: (result) {
              setState(() {
                _speechText = result.recognizedWords;
                _textController.text = _speechText; // Update text field in real-time
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
            content: Text("Permission to access microphone permanently denied. Please enable from settings."),
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
      appBar: AppBar(
        title: const Text(
          "NetBOT",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: const Color(0xFF23272A), // Darker app bar
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _predefinedSuggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(suggestion, style: const TextStyle(color: Colors.white70)),
                      backgroundColor: const Color(0xFF424549), // Darker chip background
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              return Card(
                                color: const Color(0xFF2C2F33), // Card background
                                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                elevation: 2,
                                child: ListTile(
                                  leading: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                                  title: Text(
                                    session.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    DateFormat('MMM d, yyyy hh:mm a').format(session.lastMessageTime),
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context); // Close the bottom sheet
                                    _loadMessages(session.id);
                                  },
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Chat?'),
                                          content: const Text('Are you sure you want to delete this chat history?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat session deleted.')),
    );
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
              icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF99AAB5)), // Lighter icon color
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Container(
                        color: const Color(0xFF2C2F33), // Bottom sheet background
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.camera_alt, color: Colors.white70),
                              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library, color: Colors.white70),
                              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
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
                  style: const TextStyle(color: Colors.white), // Text input color
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

    final textColor = Colors.white; // White for both for better contrast on dark background

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
              )
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
                padding: EdgeInsets.only(top: message.image != null ? 8.0 : 4.0),
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