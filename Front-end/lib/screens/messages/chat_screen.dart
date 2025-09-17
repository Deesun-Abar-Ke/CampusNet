import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../home/profile/profile_page.dart';
import '../../services/message_service.dart';
import '../../services/current_user_service.dart';
import '../../models/user_model.dart';
import '../../models/user_model.dart'; // Add MessageModel import
import '../../config.dart';

class ChatScreen extends StatefulWidget {
  final int? conversationId;
  final String contactName;
  final String avatar;
  final bool isOnline;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    this.conversationId,
    required this.contactName,
    required this.avatar,
    required this.isOnline,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      _loadMessages();
    } else {
      // For new chats without conversation ID yet
      setState(() {
        _isLoading = false;
      });
    }
    
    // Add initial message if provided
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (widget.conversationId == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _messageService.getMessages(widget.conversationId!);
      
      if (!mounted) return; // Check if widget is still mounted
      
      if (result['success']) {
        final currentUserId = await CurrentUserService.getCurrentUserId();
        final messages = (result['messages'] as List)
            .map((msg) {
              final message = MessageModel.fromJson(msg);
              // Override isMe based on frontend user check
              final actualIsMe = currentUserId != null && msg['sender_id'] == currentUserId;
              return MessageModel(
                id: message.id,
                content: message.content,
                sentAt: message.sentAt,
                senderName: message.senderName,
                messageType: message.messageType,
                isMe: actualIsMe,
                fileUrl: message.fileUrl,
                fileName: message.fileName,
                fileType: message.fileType,
                fileSize: message.fileSize,
              );
            })
            .toList();
        
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _errorMessage = 'Error loading messages: $e';
        _isLoading = false;
      });
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
      
      final uri = Uri.parse(fixedUrl);
      
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
        _showErrorSnackBar('Could not open file');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
          },
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(widget.avatar),
                  ),
                  if (widget.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contactName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.isOnline ? 'Online' : 'Last seen recently',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('View Profile'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                // Navigate to profile
              } else if (value == 'clear') {
                // Clear chat functionality
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
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
                          onPressed: _loadMessages,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send a message to start the conversation',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return MessageBubble(
                          text: message.content,
                          isMe: message.isMe,
                          time: _formatTime(message.sentAt),
                          contactAvatar: message.isMe ? null : _getAvatarForSender(message.senderName),
                          messageType: message.messageType,
                          fileUrl: message.fileUrl,
                          fileName: message.fileName,
                          fileType: message.fileType,
                          messageId: message.id,
                          onDelete: () => _deleteMessageFromList(message.id),
                        );
                      },
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
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isSending ? Colors.grey : Colors.teal,
                  child: _isSending 
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
                        onPressed: _isSending ? null : () => _sendMessage(),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // If no conversation ID, we need to create a conversation first
      // This would typically be handled when creating a new chat
      if (widget.conversationId != null) {
        final result = await _messageService.sendMessage(
          conversationId: widget.conversationId!,
          content: messageText,
        );

        if (!mounted) return; // Check if widget is still mounted

        if (result['success']) {
          _messageController.clear();
          
          // Add the message to local list for immediate UI update
          final newMessage = MessageModel.fromJson(result['message']);
          setState(() {
            _messages.add(newMessage);
            _isSending = false;
          });
        } else {
          _showErrorSnackBar(result['message'] ?? 'Failed to send message');
          setState(() {
            _isSending = false;
          });
        }
      } else {
        _showErrorSnackBar('Cannot send message: No conversation found');
        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      _showErrorSnackBar('Error sending message: $e');
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _deleteMessageFromList(int messageId) async {
    try {
      // Call the API to delete the message
      final result = await _messageService.deleteMessage(messageId);
      
      if (result['success']) {
        // Remove the message from the local list and refresh UI
        setState(() {
          _messages.removeWhere((message) => message.id == messageId);
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Message deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show network error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return 'now';
    }
  }

  String _getAvatarForSender(String senderName) {
    // In a 1-on-1 chat, if it's not me, it should be the contact
    if (senderName.toLowerCase() == widget.contactName.toLowerCase()) {
      return widget.avatar;
    }
    
    // If the sender name doesn't match the contact name, generate a unique avatar
    // This handles cases where there might be multiple participants
    const availableAvatars = ['🧑‍💼', '👩‍💼', '🧑‍🎓', '👩‍🎓', '🧑‍🏫', '👩‍🏫', '🧑‍💻', '👩‍💻', '🧑‍🔬', '👩‍🔬'];
    final hash = senderName.hashCode.abs();
    return availableAvatars[hash % availableAvatars.length];
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

  void _handleCameraSelection(BuildContext context) async {
    Navigator.pop(context);
    
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          ),
        );
        
        // Upload the image - handle both web and mobile
        Map<String, dynamic> uploadResult;
        if (kIsWeb) {
          // Web platform - read bytes
          final bytes = await image.readAsBytes();
          uploadResult = await _messageService.uploadFile(
            null,
            image.name,
            fileBytes: bytes,
          );
        } else {
          // Mobile platform - use path
          uploadResult = await _messageService.uploadFile(
            image.path,
            image.name,
          );
        }
        
        // Close loading dialog
        Navigator.pop(context);
        
        if (uploadResult['success']) {
          // Send the image message
          if (widget.conversationId != null) {
            final sendResult = await _messageService.sendFileMessage(
              conversationId: widget.conversationId!,
              fileUrl: uploadResult['file_url'],
              fileName: uploadResult['file_name'],
              fileType: uploadResult['file_type'],
              caption: 'Photo',
            );
            
            if (sendResult['success']) {
              _loadMessages(); // Reload messages to show the new image
            } else {
              _showErrorSnackBar(sendResult['message']);
            }
          }
        } else {
          _showErrorSnackBar(uploadResult['message']);
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorSnackBar('Error capturing photo: $e');
    }
  }

  void _handleGallerySelection(BuildContext context) async {
    Navigator.pop(context);
    
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Check file size (100MB limit)
        final fileSize = kIsWeb 
            ? (await image.readAsBytes()).length 
            : await File(image.path).length();
        
        if (fileSize > 100 * 1024 * 1024) {
          final sizeInMB = fileSize / (1024 * 1024);
          _showErrorSnackBar('Image too large. Maximum size is 100MB. Your image is ${sizeInMB.toStringAsFixed(1)}MB');
          return;
        }
        
        // Show image preview
        await _showImagePreviewDialog(image);
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _showImagePreviewDialog(XFile image) async {
    final TextEditingController captionController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        captionController.dispose();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Send Image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),
              
              // Image preview
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? FutureBuilder<Uint8List>(
                              future: image.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                }
                                return const Center(child: CircularProgressIndicator(color: Colors.teal));
                              },
                            )
                          : Image.file(
                              File(image.path),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image, size: 60, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Image Preview'),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
              
              // Caption input area (WhatsApp-like)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: captionController,
                              decoration: const InputDecoration(
                                hintText: 'Add a caption...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              backgroundColor: Colors.teal,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final caption = captionController.text.trim();
                                  captionController.dispose();
                                  await _uploadAndSendImage(image, caption: caption.isNotEmpty ? caption : null);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            captionController.dispose();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final caption = captionController.text.trim();
                            captionController.dispose();
                            await _uploadAndSendImage(image, caption: caption.isNotEmpty ? caption : null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Text('Send Image'),
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
      ),
    );
  }

  Future<void> _uploadAndSendImage(XFile image, {String? caption}) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(width: 16),
            Text('Uploading image...'),
          ],
        ),
      ),
    );
    
    try {
      // Upload the image - handle both web and mobile
      Map<String, dynamic> uploadResult;
      if (kIsWeb) {
        // Web platform - read bytes
        final bytes = await image.readAsBytes();
        uploadResult = await _messageService.uploadFile(
          null,
          image.name,
          fileBytes: bytes,
        );
      } else {
        // Mobile platform - use path
        uploadResult = await _messageService.uploadFile(
          image.path,
          image.name,
        );
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (uploadResult['success']) {
        // Send the image message
        if (widget.conversationId != null) {
          final sendResult = await _messageService.sendFileMessage(
            conversationId: widget.conversationId!,
            fileUrl: uploadResult['file_url'],
            fileName: uploadResult['file_name'],
            fileType: uploadResult['file_type'],
            caption: caption ?? 'Image',
          );
          
          if (sendResult['success']) {
            _loadMessages(); // Reload messages to show the new image
          } else {
            _showErrorSnackBar(sendResult['message']);
          }
        }
      } else {
        _showErrorSnackBar(uploadResult['message']);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorSnackBar('Error uploading image: $e');
    }
  }

  void _handleDocumentSelection(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // Important for web - loads file bytes
      );
      
      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        // Check file size (100MB limit)
        const maxSize = 100 * 1024 * 1024; // 100MB in bytes
        if (file.size > maxSize) {
          final sizeInMB = file.size / (1024 * 1024);
          _showErrorSnackBar('File too large. Maximum size is 100MB. Your file is ${sizeInMB.toStringAsFixed(1)}MB');
          return;
        }
        
        // Show file preview dialog with send option - works for both web and mobile
        await _showFilePreviewDialog(file);
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting document: $e');
    }
  }

  Future<void> _showFilePreviewDialog(PlatformFile file) async {
    final TextEditingController captionController = TextEditingController();
    final sizeInMB = file.size / (1024 * 1024);
    final sizeStr = sizeInMB < 1 
        ? '${(file.size / 1024).toStringAsFixed(1)} KB'
        : '${sizeInMB.toStringAsFixed(1)} MB';
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        captionController.dispose();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Send Document',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),
              
              // File preview
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.withOpacity(0.3)),
                          ),
                          child: Icon(
                            _getFileIcon(file.extension ?? ''),
                            size: 60,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          file.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sizeStr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Caption input area (WhatsApp-like)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: captionController,
                              decoration: const InputDecoration(
                                hintText: 'Add a caption...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              backgroundColor: Colors.teal,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final caption = captionController.text.trim();
                                  captionController.dispose();
                                  await _uploadAndSendFile(file, caption: caption.isNotEmpty ? caption : null);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        captionController.dispose();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _uploadAndSendFile(PlatformFile file, {String? caption}) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(width: 16),
            Text('Uploading file...'),
          ],
        ),
      ),
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
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Could not access file data');
        return;
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (uploadResult['success']) {
        // Send the file message
        if (widget.conversationId != null) {
          final sendResult = await _messageService.sendFileMessage(
            conversationId: widget.conversationId!,
            fileUrl: uploadResult['file_url'],
            fileName: uploadResult['file_name'],
            fileType: uploadResult['file_type'],
            caption: caption ?? file.name,
          );
          
          if (sendResult['success']) {
            _loadMessages(); // Reload messages to show the new file
          } else {
            _showErrorSnackBar(sendResult['message']);
          }
        }
      } else {
        _showErrorSnackBar(uploadResult['message']);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorSnackBar('Error uploading file: $e');
    }
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon, 
                color: Colors.white, 
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final String? contactAvatar;
  final String messageType;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final int? messageId;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    this.contactAvatar,
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.messageId,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && contactAvatar != null) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.teal[100],
              child: Text(contactAvatar!, style: const TextStyle(fontSize: 10)),
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
                  _buildMessageContent(context),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.done_all,
              size: 16,
              color: Colors.blue[600],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (messageType) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileUrl != null)
              GestureDetector(
                onTap: () {
                  final url = fileUrl!.startsWith('http') ? fileUrl! : '${Config.baseUrl}${fileUrl!}?download=1';
                  final state = context.findAncestorStateOfType<_ChatScreenState>();
                  state?._openFileUrl(url);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fileUrl!.startsWith('http') ? fileUrl! : '${Config.baseUrl}${fileUrl!}',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Image not found',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (text.isNotEmpty && text != (fileName ?? ''))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      case 'file':
        return GestureDetector(
          onTap: () {
            final url = (fileUrl ?? '').startsWith('http') ? (fileUrl ?? '') : '${Config.baseUrl}${fileUrl ?? ''}?download=1';
            final state = context.findAncestorStateOfType<_ChatScreenState>();
            state?._openFileUrl(url);
          },
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                color: isMe ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? 'Unknown file',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (text.isNotEmpty && text != fileName)
                      Text(
                        text,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
    }
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

  void _deleteMessage(BuildContext context) {
    if (messageId == null || onDelete == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete this message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
              onDelete!(); // Call the delete callback
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
}
