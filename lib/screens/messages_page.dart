import 'package:flutter/material.dart';
import 'study_materials/group_resources_page.dart';
import '../widgets/common_app_bar.dart';

class MessagesPage extends StatefulWidget {
  final String? initialContact;
  final String? initialMessage;

  const MessagesPage({
    Key? key,
    this.initialContact,
    this.initialMessage,
  }) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // If initial contact is provided, navigate to chat
    if (widget.initialContact != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contactName: widget.initialContact!,
              avatar: '👨‍🎓',
              isOnline: true,
              initialMessage: widget.initialMessage,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(
        title: Text('Messages'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.teal,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'CHATS'),
                Tab(text: 'GROUPS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                IndividualChatsTab(),
                GroupChatsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOptions(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
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
              leading: const Icon(Icons.person_add, color: Colors.teal),
              title: const Text('Start New Chat'),
              onTap: () {
                Navigator.pop(context);
                _showNewChatDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.teal),
              title: const Text('Create Group'),
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NewChatDialog(),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }
}

class IndividualChatsTab extends StatelessWidget {
  const IndividualChatsTab({super.key});

  final List<Map<String, dynamic>> chats = const [
    {
      'name': 'MD. Nahian Kabir Pranto',
      'lastMessage': 'Thanks for the math help!',
      'time': '2:30 PM',
      'unreadCount': 2,
      'avatar': '👨‍🎓',
      'isOnline': true,
    },
    {
      'name': 'Fatima Rahman',
      'lastMessage': 'Can we schedule a physics session?',
      'time': '1:15 PM',
      'unreadCount': 0,
      'avatar': '👩‍🔬',
      'isOnline': false,
    },
    {
      'name': 'Samiya Hasan Anka',
      'lastMessage': 'The accounting notes were helpful',
      'time': 'Yesterday',
      'unreadCount': 1,
      'avatar': '👩‍💼',
      'isOnline': true,
    },
    {
      'name': 'Jannatul Ferdous',
      'lastMessage': 'See you in the English class',
      'time': 'Yesterday',
      'unreadCount': 0,
      'avatar': '📚',
      'isOnline': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatTile(
          name: chat['name'],
          lastMessage: chat['lastMessage'],
          time: chat['time'],
          unreadCount: chat['unreadCount'],
          avatar: chat['avatar'],
          isOnline: chat['isOnline'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  contactName: chat['name'],
                  avatar: chat['avatar'],
                  isOnline: chat['isOnline'],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GroupChatsTab extends StatelessWidget {
  const GroupChatsTab({super.key});

  final List<Map<String, dynamic>> groups = const [
    {
      'name': 'CSE 303 - Compilers',
      'lastMessage': 'New assignment posted',
      'time': '3:45 PM',
      'unreadCount': 5,
      'memberCount': 45,
      'avatar': '💻',
      'courseFolder': 'Computer Science & Engineering/Compilers (CSE 303)',
    },
    {
      'name': 'AI Study Group',
      'lastMessage': 'Meeting tomorrow at 2 PM',
      'time': '1:20 PM',
      'unreadCount': 12,
      'memberCount': 23,
      'avatar': '🤖',
      'courseFolder': 'Computer Science & Engineering/Artificial Intelligence',
    },
    {
      'name': 'Chemistry Lab Partners',
      'lastMessage': 'Lab report due Friday',
      'time': 'Yesterday',
      'unreadCount': 0,
      'memberCount': 8,
      'avatar': '🧪',
      'courseFolder': 'Chemical Engineering/Chemistry Fundamentals (CHEM - 101)',
    },
    {
      'name': 'Math Study Circle',
      'lastMessage': 'Practice problems shared',
      'time': 'Yesterday',
      'unreadCount': 3,
      'memberCount': 15,
      'avatar': '📐',
      'courseFolder': 'Architecture/Linear Algebra',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return GroupTile(
          name: group['name'],
          lastMessage: group['lastMessage'],
          time: group['time'],
          unreadCount: group['unreadCount'],
          memberCount: group['memberCount'],
          avatar: group['avatar'],
          courseFolder: group['courseFolder'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatScreen(
                  groupName: group['name'],
                  memberCount: group['memberCount'],
                  avatar: group['avatar'],
                  courseFolder: group['courseFolder'],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String avatar;
  final bool isOnline;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.avatar,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.teal[100],
            child: Text(
              avatar,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          if (isOnline)
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
      title: Text(
        name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        lastMessage,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              color: unreadCount > 0 ? Colors.teal : Colors.grey[500],
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class GroupTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final int memberCount;
  final String avatar;
  final String courseFolder;
  final VoidCallback onTap;

  const GroupTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.memberCount,
    required this.avatar,
    required this.courseFolder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.teal[100],
        child: Text(
          avatar,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lastMessage,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$memberCount members',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              color: unreadCount > 0 ? Colors.teal : Colors.grey[500],
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class NewChatDialog extends StatefulWidget {
  const NewChatDialog({super.key});

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  String searchQuery = '';
  
  final List<Map<String, dynamic>> allUsers = [
    {'name': 'Rakib Ahmed', 'avatar': '👨‍🎓', 'isOnline': true},
    {'name': 'Sarah Khan', 'avatar': '👩‍💻', 'isOnline': false},
    {'name': 'Ahmed Hassan', 'avatar': '👨‍🔬', 'isOnline': true},
    {'name': 'Nadia Rahman', 'avatar': '👩‍🎓', 'isOnline': true},
    {'name': 'Karim Uddin', 'avatar': '👨‍💼', 'isOnline': false},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredUsers = allUsers
        .where((user) => user['name']
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    return AlertDialog(
      title: const Text('Start New Chat'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          child: Text(user['avatar']),
                        ),
                        if (user['isOnline'])
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
                    title: Text(user['name']),
                    subtitle: Text(user['isOnline'] ? 'Online' : 'Offline'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            contactName: user['name'],
                            avatar: user['avatar'],
                            isOnline: user['isOnline'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  String groupName = '';
  String selectedCourse = '';
  final List<String> selectedMembers = [];

  final List<String> courses = [
    'Computer Science & Engineering/Artificial Intelligence',
    'Computer Science & Engineering/C Language Theory',
    'Computer Science & Engineering/Compilers (CSE 303)',
    'Computer Science & Engineering/Data Structures',
    'Chemical Engineering/Chemistry Fundamentals (CHEM - 101)',
    'Chemical Engineering/Organic Chemistry',
    'Architecture/Linear Algebra',
    'Architecture/Calculus',
  ];

  final List<Map<String, dynamic>> allUsers = [
    {'name': 'Rakib Ahmed', 'avatar': '👨‍🎓'},
    {'name': 'Sarah Khan', 'avatar': '👩‍💻'},
    {'name': 'Ahmed Hassan', 'avatar': '👨‍🔬'},
    {'name': 'Nadia Rahman', 'avatar': '👩‍🎓'},
    {'name': 'Karim Uddin', 'avatar': '👨‍💼'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Group'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => groupName = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Link to Course (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: courses.map((course) {
                return DropdownMenuItem(
                  value: course,
                  child: Text(
                    course.split('/').last,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => selectedCourse = value ?? '',
            ),
            const SizedBox(height: 16),
            const Text('Add Members:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  final user = allUsers[index];
                  final isSelected = selectedMembers.contains(user['name']);
                  
                  return ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedMembers.add(user['name']);
                          } else {
                            selectedMembers.remove(user['name']);
                          }
                        });
                      },
                    ),
                    title: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          child: Text(user['avatar']),
                        ),
                        const SizedBox(width: 12),
                        Text(user['name']),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedMembers.remove(user['name']);
                        } else {
                          selectedMembers.add(user['name']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: groupName.isNotEmpty && selectedMembers.isNotEmpty
              ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "$groupName" created with ${selectedMembers.length} members'),
                    ),
                  );
                }
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String avatar;
  final bool isOnline;
  final String? initialMessage;

  const ChatScreen({
    super.key,
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
  final List<Map<String, dynamic>> messages = [
    {
      'text': 'Hi! How are you doing?',
      'isMe': false,
      'time': '2:25 PM',
      'type': 'text',
    },
    {
      'text': 'I\'m good! Thanks for asking. How about you?',
      'isMe': true,
      'time': '2:26 PM',
      'type': 'text',
    },
    {
      'text': 'Can you help me with the math assignment?',
      'isMe': false,
      'time': '2:28 PM',
      'type': 'text',
    },
    {
      'text': 'Of course! Which topic?',
      'isMe': true,
      'time': '2:29 PM',
      'type': 'text',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Row(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call feature coming soon!')),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Text('Contact Info'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                setState(() {
                  messages.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat cleared')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return MessageBubble(
                  text: message['text'],
                  isMe: message['isMe'],
                  time: message['time'],
                  contactAvatar: widget.avatar,
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
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add({
          'text': _messageController.text.trim(),
          'isMe': true,
          'time': 'now',
          'type': 'text',
        });
      });
      _messageController.clear();
    }
  }

  void _showAttachmentOptions(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.red,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
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
}

class GroupChatScreen extends StatefulWidget {
  final String groupName;
  final int memberCount;
  final String avatar;
  final String courseFolder;

  const GroupChatScreen({
    super.key,
    required this.groupName,
    required this.memberCount,
    required this.avatar,
    required this.courseFolder,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [
    {
      'text': 'New assignment has been posted!',
      'sender': 'Prof. Rahman',
      'isMe': false,
      'time': '3:40 PM',
      'type': 'text',
    },
    {
      'text': 'Thanks for the update!',
      'sender': 'You',
      'isMe': true,
      'time': '3:42 PM',
      'type': 'text',
    },
    {
      'text': 'Can someone share the lecture notes?',
      'sender': 'Ahmed Hassan',
      'isMe': false,
      'time': '3:45 PM',
      'type': 'text',
    },
  ];

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
              onPressed: () => _showResourcesDialog(context),
              tooltip: 'Group Resources',
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Text('Group Info'),
              ),
              const PopupMenuItem(
                value: 'members',
                child: Text('Members'),
              ),
              if (widget.courseFolder.isNotEmpty)
                const PopupMenuItem(
                  value: 'resources',
                  child: Text('Course Resources'),
                ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'resources':
                  _showResourcesDialog(context);
                  break;
                case 'members':
                  _showMembersDialog(context);
                  break;
                case 'clear':
                  setState(() {
                    messages.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat cleared')),
                  );
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return GroupMessageBubble(
                  text: message['text'],
                  sender: message['sender'],
                  isMe: message['isMe'],
                  time: message['time'],
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
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add({
          'text': _messageController.text.trim(),
          'sender': 'You',
          'isMe': true,
          'time': 'now',
          'type': 'text',
        });
      });
      _messageController.clear();
    }
  }

  void _showResourcesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder, color: Colors.teal[700]),
            const SizedBox(width: 8),
            const Text('Course Resources'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.teal[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This group is linked to:\n${widget.courseFolder}',
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.blue),
                title: const Text('Browse Course Materials'),
                subtitle: const Text('Open study materials folder'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupResourcesPage(
                        groupName: widget.groupName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showShareResourceDialog(BuildContext context) {
    String resourceName = '';
    String description = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Resource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Resource Name',
                hintText: 'e.g., Lecture 5 Notes, Assignment 2',
              ),
              onChanged: (value) => resourceName = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the resource',
              ),
              maxLines: 3,
              onChanged: (value) => description = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: resourceName.isNotEmpty
                ? () {
                    Navigator.pop(context);
                    setState(() {
                      messages.add({
                        'text': '📁 Shared: $resourceName${description.isNotEmpty ? '\n$description' : ''}',
                        'sender': 'You',
                        'isMe': true,
                        'time': 'now',
                        'type': 'resource',
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resource shared with group!')),
                    );
                  }
                : null,
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showMembersDialog(BuildContext context) {
    final members = [
      {'name': 'Prof. Rahman', 'role': 'Admin', 'avatar': '👨‍🏫'},
      {'name': 'You', 'role': 'Member', 'avatar': '👨‍🎓'},
      {'name': 'Ahmed Hassan', 'role': 'Member', 'avatar': '👨‍🔬'},
      {'name': 'Sarah Khan', 'role': 'Member', 'avatar': '👩‍💻'},
      {'name': 'Nadia Rahman', 'role': 'Member', 'avatar': '👩‍🎓'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.groupName} Members'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal[100],
                  child: Text(member['avatar']!),
                ),
                title: Text(member['name']!),
                subtitle: Text(member['role']!),
                trailing: member['role'] == 'Admin'
                    ? Icon(Icons.admin_panel_settings, color: Colors.teal[700])
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.red,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.folder,
                  label: 'Resource',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    _showShareResourceDialog(context);
                  },
                ),
              ],
            ),
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
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final String? contactAvatar;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    this.contactAvatar,
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
              radius: 16,
              backgroundColor: Colors.teal[100],
              child: Text(
                contactAvatar!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
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
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal[100],
              child: const Text(
                '👨‍🎓',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
          Container(
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
                  Text(
                    sender,
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
}
