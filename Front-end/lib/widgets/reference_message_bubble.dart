import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/messages/group_resources/group_resources_page.dart';

class ReferenceMessageBubble extends StatelessWidget {
  final String text;
  final String reference;
  final String sender;
  final bool isMe;
  final String time;
  final List<String>? folderPath; // Add folder path for navigation

  const ReferenceMessageBubble({
    super.key,
    required this.text,
    required this.reference,
    required this.sender,
    required this.isMe,
    required this.time,
    this.folderPath,
  });

  String _getAvatarForSender(String sender) {
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
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal[100],
              child: Text(
                _getAvatarForSender(sender),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onLongPress: () => _showMessageOptions(context),
            onTap: () => _navigateToResource(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.teal[600] : Colors.blue[100],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isMe ? Colors.teal[800]! : Colors.blue[300]!,
                  width: 1,
                ),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                  if (!isMe) const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.link,
                        color: isMe ? Colors.white : Colors.blue[700],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.blue[800],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to open',
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.blue[600],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
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

  void _showReferenceDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link, color: Colors.blue),
            SizedBox(width: 8),
            Text('Resource Reference'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.replaceFirst('📎 Resource Reference: ', ''),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reference,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToResource(context);
            },
            child: Text(folderPath != null ? 'Open Folder' : 'Open Resource'),
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.forward, color: Colors.blue),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(context);
              },
            ),
            if (isMe)
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
              title: const Text('Copy Reference'),
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
      const SnackBar(content: Text('Forward reference functionality coming soon!')),
    );
  }

  void _deleteMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reference'),
        content: const Text('Are you sure you want to delete this reference?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reference deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: reference));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference copied to clipboard')),
    );
  }

  void _navigateToResource(BuildContext context) {
    if (folderPath != null) {
      // Navigate directly to the group resources page with folder path
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupResourcesPage(
            groupName: 'CSE 303 - Compilers', // This should be dynamic
            initialPath: folderPath,
          ),
          settings: const RouteSettings(name: '/group_resources'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening resource...')),
      );
    }
  }
}
