import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'group_resources/group_resources_page.dart';
import 'group_resources/add_member_page.dart';
import 'group_resources/view_members_page.dart';
import 'dynamic_group_resource.dart';
import '../../widgets/reference_message_bubble.dart';
import '../../services/message_service.dart';
import '../../services/current_user_service.dart';
import '../../config.dart';
import 'chat_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final int? conversationId;
  final String groupName;
  final int memberCount;
  final String avatar;
  final String courseFolder;
  final Map<String, dynamic>? initialReference;
  final String? currentUserId;

  const GroupChatScreen({
    super.key,
    this.conversationId,
    required this.groupName,
    required this.memberCount,
    required this.avatar,
    required this.courseFolder,
  this.initialReference,
    this.currentUserId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;
  String? _errorMessage;
  Map<String, dynamic>? _pendingReference;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // If launched with a reference, keep it pending and prefill composer
    if (widget.initialReference != null) {
      _pendingReference = widget.initialReference;
      // optionally prefill composer text with file or folder name
      final prefill = widget.initialReference!['file_name'] ?? widget.initialReference!['folder_name'] ?? '';
      if (prefill.isNotEmpty) {
        _messageController.text = prefill;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (widget.conversationId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid conversation ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _messageService.getMessages(widget.conversationId!);
      
      if (result['success']) {
        // Get current user ID for message comparison
        final currentUserId = CurrentUserService.getCurrentUserId();
        
        final messages = (result['messages'] as List)
            .map((message) => {
              'id': message['id'],
              'text': message['content'] ?? '',
              'sender': message['sender_name'] ?? 'Unknown',
              'senderId': message['sender_id'],
              'isMe': message['sender_id'] == currentUserId, // Proper comparison: int == int
              'time': _formatTime(message['sent_at'] ?? ''),
              'type': message['message_type'] ?? 'text',
              'timestamp': message['sent_at'],
              'fileUrl': message['file_url'],
              'fileName': message['file_name'],
              'fileType': message['file_type'],
              // Map reference_data to folderPath for ReferenceMessageBubble
              'folderPath': message['reference_data'] != null ? message['reference_data']['folder_path'] : null,
              'reference': message['reference_data'] != null ? (message['reference_data']['file_name'] ?? message['content']) : null,
            })
            .toList();

        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading messages: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (messageDate == today) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'now';
    }
  }

  Future<void> _sendMessage() async {
    if ((_messageController.text.trim().isEmpty && _pendingReference == null) || _isSendingMessage || widget.conversationId == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    // don't clear before sending; clear after success

    setState(() {
      _isSendingMessage = true;
    });

    try {
      print('DEBUG - Sending message with pending reference: $_pendingReference');
      final result = await _messageService.sendMessage(
        conversationId: widget.conversationId!,
        content: messageText.isNotEmpty ? messageText : (_pendingReference != null ? (_pendingReference!['file_name'] ?? 'Reference') : ''),
        messageType: _pendingReference != null ? 'reference' : 'text',
        referenceData: _pendingReference,
      );

      if (result['success']) {
        // Get current user ID for the new message
        final currentUserId = CurrentUserService.getCurrentUserId();
        
        // Add the message to the local list immediately for better UX
        final newMessage = {
          'id': result['message_id'] ?? DateTime.now().millisecondsSinceEpoch,
          'text': messageText.isNotEmpty ? messageText : (_pendingReference != null ? (_pendingReference!['file_name'] ?? 'Reference') : ''),
          'sender': 'You',
          'senderId': currentUserId,
          'isMe': true,
          'time': 'now',
          'type': _pendingReference != null ? 'reference' : 'text',
          'timestamp': DateTime.now().toIso8601String(),
          'folderPath': _pendingReference != null ? _pendingReference!['folder_path'] : null,
          'reference': _pendingReference != null ? (_pendingReference!['file_name'] ?? '') : null,
        };

        setState(() {
          _messages.add(newMessage);
          _isSendingMessage = false;
          _pendingReference = null; // clear pending after send
          _messageController.clear();
        });
      } else {
        setState(() {
          _isSendingMessage = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      setState(() {
        _isSendingMessage = false;
      });
      _showErrorSnackBar('Error sending message: $e');
    }
  }

  void _composeReference(Map<String, dynamic> ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Reference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Posting reference: ${ref['file_name'] ?? ''}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Add a description (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final description = controller.text.trim();
              Navigator.pop(context);
              // Send message with reference_data
              final result = await _messageService.sendMessage(
                conversationId: widget.conversationId!,
                content: description.isNotEmpty ? description : '${ref['file_name'] ?? 'Reference'}',
                messageType: 'reference',
                referenceData: ref,
              );

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reference posted')),
                );
                _loadMessages();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to post reference: ${result['message']}')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(widget.avatar),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.memberCount} members',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.courseFolder.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupResourcesPage(
                      groupName: widget.groupName,
                    ),
                    settings: const RouteSettings(name: '/group_resources'),
                  ),
                );
              },
              tooltip: 'Group Resources',
            ),
          // New Dynamic Group Resources Icon
          IconButton(
            icon: const Icon(Icons.folder_shared),
            onPressed: () {
              print('DEBUG - Conversation ID: ${widget.conversationId}');
              if (widget.conversationId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DynamicGroupResourcePage(
                      groupName: widget.groupName,
                      conversationId: widget.conversationId!,
                    ),
                    settings: const RouteSettings(name: '/dynamic_group_resources'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversation ID not available'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Dynamic Resources',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('View Members'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_member',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Add Member'),
                  ],
                ),
              ),
              if (widget.courseFolder.isNotEmpty)
                const PopupMenuItem(
                  value: 'resources',
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined, color: Colors.purple, size: 20),
                      SizedBox(width: 8),
                      Text('Course Resources'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text('Search Messages'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Leave Group'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'resources':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupResourcesPage(
                        groupName: widget.groupName,
                      ),
                      settings: const RouteSettings(name: '/group_resources'),
                    ),
                  );
                  break;
                case 'members':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewMembersPage(
                        groupName: widget.groupName,
                        conversationId: widget.conversationId,
                      ),
                      settings: const RouteSettings(name: '/view_members'),
                    ),
                  );
                  break;
                case 'add_member':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMemberPage(
                        groupName: widget.groupName,
                        conversationId: widget.conversationId,
                      ),
                      settings: const RouteSettings(name: '/add_member'),
                    ),
                  );
                  break;
                case 'search':
                  _showSearchDialog(context);
                  break;
                case 'refresh':
                  await _refreshMessages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Messages refreshed')),
                  );
                  break;
                case 'leave':
                  _showLeaveGroupDialog(context);
                  break;
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshMessages,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshMessages,
                        child: _messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet.\nSend the first message!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  if (message['type'] == 'reference') {
                                    return ReferenceMessageBubble(
                                      text: message['text'] ?? '',
                                      reference: message['reference'] ?? '',
                                      sender: message['sender'] ?? 'Unknown',
                                      isMe: message['isMe'] ?? false,
                                      time: message['time'] ?? '',
                                      folderPath: message['folderPath'] != null
                                          ? List<Map<String, dynamic>>.from(message['folderPath'])
                                          : null,
                                      conversationId: widget.conversationId,
                                    );
                                  } else {
                                    return GroupMessageBubble(
                                      text: message['text'] ?? '',
                                      sender: message['sender'] ?? 'Unknown',
                                      isMe: message['isMe'] ?? false,
                                      time: message['time'] ?? '',
                                      fileUrl: message['fileUrl'],
                                      fileName: message['fileName'],
                                      fileType: message['fileType'],
                                    );
                                  }
                                },
                              ),
                      ),
                    ),
                    // Composer area with optional pending reference preview
                    if (_pendingReference != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.link, color: Colors.teal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pendingReference!['file_name'] ?? _pendingReference!['folder_name'] ?? 'Reference',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _pendingReference = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.teal),
                            onPressed: () {
                              _showAttachmentOptions(context);
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              maxLines: null,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: _isSendingMessage ? Colors.grey : Colors.teal,
                            child: _isSendingMessage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white),
                                    onPressed: _sendMessage,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search in conversation...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => searchQuery = value,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Recent searches:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['assignment', 'notes', 'exam', 'project']
                  .map((term) => ActionChip(
                        label: Text(term),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Searching for "$term"...')),
                          );
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Searching for "$searchQuery"...')),
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${widget.groupName}"? You won\'t be able to see new messages unless someone adds you back.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.conversationId != null) {
      try {
        final currentUserId = CurrentUserService.getCurrentUserId();
        if (currentUserId != null) {
          final result = await _messageService.removeParticipant(
            widget.conversationId!,
            currentUserId,
          );

          if (result['success']) {
            Navigator.pop(context); // Go back to messages list
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Left ${widget.groupName}')),
            );
          } else {
            _showErrorSnackBar(result['message'] ?? 'Failed to leave group');
          }
        } else {
          _showErrorSnackBar('Unable to get current user information');
        }
      } catch (e) {
        _showErrorSnackBar('Error leaving group: $e');
      }
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Send File',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what you want to share',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: const Color(0xFF25D366),
                  onTap: () => _handleCameraSelection(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: const Color(0xFF128C7E),
                  onTap: () => _handleGallerySelection(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: const Color(0xFF075E54),
                  onTap: () => _handleDocumentSelection(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 25,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _handleCameraSelection(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Uploading photo..."),
                ],
              ),
            );
          },
        );
        
        try {
          // Convert XFile to PlatformFile for upload
          final bytes = await image.readAsBytes();
          
          // Upload file and send message
          final uploadResult = await _messageService.uploadFile(
            image.path, 
            image.name, 
            fileBytes: bytes
          );
          
          if (uploadResult['success']) {
            final sendResult = await _messageService.sendFileMessage(
              conversationId: widget.conversationId!,
              fileUrl: uploadResult['file_url'],
              fileName: image.name,
              fileType: image.path.split('.').last,
              caption: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null,
            );
            
            // Safely close loading dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            if (sendResult['success']) {
              _messageController.clear();
              await _loadMessages(); // Refresh messages
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Photo sent: ${image.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send photo: ${sendResult['error'] ?? 'Unknown error'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Safely close loading dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload photo: ${uploadResult['error'] ?? 'Unknown error'}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          // Safely close loading dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading photo: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to access camera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleGallerySelection(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Uploading image..."),
                ],
              ),
            );
          },
        );
        
        try {
          // Convert XFile to PlatformFile for upload
          final bytes = await image.readAsBytes();
          
          // Upload file and send message
          final uploadResult = await _messageService.uploadFile(
            image.path, 
            image.name, 
            fileBytes: bytes
          );
          
          if (uploadResult['success']) {
            final sendResult = await _messageService.sendFileMessage(
              conversationId: widget.conversationId!,
              fileUrl: uploadResult['file_url'],
              fileName: image.name,
              fileType: image.path.split('.').last,
              caption: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null,
            );
            
            // Safely close loading dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            if (sendResult['success']) {
              _messageController.clear();
              await _loadMessages(); // Refresh messages
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Image sent: ${image.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send image: ${sendResult['error'] ?? 'Unknown error'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Safely close loading dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload image: ${uploadResult['error'] ?? 'Unknown error'}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          // Safely close loading dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to access gallery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDocumentSelection(BuildContext context) async {
    Navigator.pop(context);
    
    print('Document selection started...');
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // Important for web - loads file bytes
      );
      
      print('File picker result: $result');
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('File selected: ${file.name}, size: ${file.size}');
        
        // Check file size (100MB limit)
        const maxSize = 100 * 1024 * 1024; // 100MB
        if (file.size > maxSize) {
          final sizeInMB = file.size / (1024 * 1024);
          print('File too large: ${sizeInMB}MB');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File too large. Maximum size is 100MB. Your file is ${sizeInMB.toStringAsFixed(1)}MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        print('Showing document preview...');
        // Show WhatsApp-like preview dialog - Use mounted check for context safety
        if (mounted) {
          _showDocumentPreview(file);
        }
      } else {
        print('No file selected');
      }
    } catch (e) {
      print('Error in document selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDocumentPreview(PlatformFile file) {
    if (!mounted) return; // Safety check
    
    final TextEditingController captionController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Send Document',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // File preview
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getFileIcon(file.extension ?? ''),
                              size: 48,
                              color: Colors.teal,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              file.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Caption input
                      TextField(
                        controller: captionController,
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                      const SizedBox(height: 20),
                      
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _uploadAndSendFile(file, captionController.text.trim());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Send'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadAndSendFile(PlatformFile file, String caption) async {
    if (!mounted) return; // Safety check
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading document..."),
            ],
          ),
        );
      },
    );
    
    try {
      // Upload the file - handle both web and mobile platforms
      Map<String, dynamic> uploadResult;
      if (file.bytes != null) {
        // Web platform - use bytes
        uploadResult = await _messageService.uploadFile(
          null, 
          file.name,
          fileBytes: file.bytes,
        );
      } else if (file.path != null) {
        // Mobile platform - use path
        uploadResult = await _messageService.uploadFile(
          file.path!, 
          file.name,
        );
      } else {
        // Safely close loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not access file data'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (uploadResult['success']) {
        final sendResult = await _messageService.sendFileMessage(
          conversationId: widget.conversationId!,
          fileUrl: uploadResult['file_url'],
          fileName: file.name,
          fileType: file.extension ?? '',
          caption: caption.isNotEmpty ? caption : null,
        );
        
        // Safely close loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        if (sendResult['success']) {
          await _loadMessages(); // Refresh messages
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Document sent: ${file.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send document: ${sendResult['error'] ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Safely close loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload document: ${uploadResult['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Safely close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class GroupMessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  final String time;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;

  const GroupMessageBubble({
    super.key,
    required this.text,
    required this.sender,
    required this.isMe,
    required this.time,
    this.fileUrl,
    this.fileName,
    this.fileType,
  });

  String _getAvatarForSender(String sender) {
    // Return different avatars for different senders
    // First check if this sender is the current user
    final currentUserId = CurrentUserService.getCurrentUserId();
    final currentUserName = CurrentUserService.getCurrentUserName();
    
    if (sender == currentUserId?.toString() || sender == currentUserName || sender == 'You') {
      return '👨‍🎓';
    }
    
    switch (sender) {
      case 'Prof. Rahman':
        return '👨‍🏫';
      case 'Ahmed Hassan':
        return '👨‍🔬';
      case 'Sarah Khan':
        return '👩‍💻';
      case 'Nadia Rahman':
        return '👩‍🎓';
      case 'Karim Uddin':
        return '👨‍💼';
      default:
        // Generate consistent avatar based on sender name hash - NO MOON ICONS
        final hash = sender.hashCode;
        final avatars = ['‍💻', '👩‍💻', '👨‍🎓', '👩‍🎓', '👨‍💼', '👩‍💼', '👨‍🔬', '👩‍🔬', '👨‍🏫', '👩‍🏫'];
        return avatars[hash.abs() % avatars.length];
    }
  }

  Future<void> _openFileUrl(String url) async {
    try {
      // Fix localhost URLs - replace with configured server IP from Config
      var fixedUrl = url;
      if (fixedUrl.contains('localhost')) {
        // Extract the server host from Config.baseUrl
        final configUri = Uri.parse(Config.baseUrl);
        final serverHost = '${configUri.host}:${configUri.port}';
        fixedUrl = fixedUrl.replaceAll('localhost:5000', serverHost);
      }
      
      final Uri uri = Uri.parse(fixedUrl);
      
      // Check if it's a PDF file by URL extension
      final isPdf = fixedUrl.toLowerCase().contains('.pdf');
      
      if (await canLaunchUrl(uri)) {
        if (isPdf) {
          // For PDFs, use platformDefault for better viewing experience
          await launchUrl(uri, mode: LaunchMode.platformDefault).catchError((e) {
            // Fallback to external application if platformDefault fails
            return launchUrl(uri, mode: LaunchMode.externalApplication);
          });
        } else {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        throw 'Could not launch $fixedUrl';
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      contactName: sender,
                      avatar: _getAvatarForSender(sender),
                      isOnline: true, // Default to online
                    ),
                    settings: const RouteSettings(name: '/chat'),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.teal[100],
                child: Text(
                  _getAvatarForSender(sender), 
                  style: const TextStyle(fontSize: 10)
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onLongPress: () => _showMessageOptions(context),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.teal[600] : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      sender,
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  
                  // File message content
                  if (fileUrl != null && fileName != null) ...[
                    GestureDetector(
                      onTap: () => _openFileUrl(fileUrl!),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal[500] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMe ? Colors.teal[300]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getFileIcon(fileType ?? ''),
                              color: isMe ? Colors.white : Colors.teal[600],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName!,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (fileType != null)
                                    Text(
                                      fileType!.toUpperCase(),
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.download,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  
                  // Text message content (if any)
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.blue[300],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(context);
              },
            ),
            if (!isMe)
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text('Message $sender'),
                onTap: () {
                  Navigator.pop(context);
                  _openPersonalChatFromMessage(context);
                },
              ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _forwardMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forward message functionality coming soon!')),
    );
  }

  void _deleteMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  void _openPersonalChatFromMessage(BuildContext context) {
    // Navigate to personal chat with the sender
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          contactName: sender,
          avatar: _getAvatarForSender(sender),
          isOnline: true, // Assume online for demo
        ),
        settings: const RouteSettings(name: '/personal_chat'),
      ),
    );
  }
}
