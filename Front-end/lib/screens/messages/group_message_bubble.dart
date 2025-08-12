import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'messages_page.dart';

class GroupMessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  final String time;

  const GroupMessageBubble({
    super.key,
    required this.text,
    required this.sender,
    required this.isMe,
    required this.time,
  });

  String _getAvatarForSender(String sender) {
    // Return different avatars for different senders
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
      case 'You':
        return '👨‍🎓';
      default:
        return '👤';
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
              onTap: () => _openPersonalChatFromMessage(context),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal[100],
                child: Text(
                  _getAvatarForSender(sender),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onLongPress: () => _showMessageOptions(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.teal : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    GestureDetector(
                      onTap: () => _openPersonalChatFromMessage(context),
                      child: Text(
                        sender,
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 2),
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
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
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal[100],
              child: Text(
                _getAvatarForSender('You'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.forward, color: Colors.blue),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.grey),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(context);
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          contactName: sender,
          avatar: _getAvatarForSender(sender),
          isOnline: true, // You can implement actual online status
        ),
      ),
    );
  }
}
