import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'new_chat_page.dart';
import 'create_group_page.dart';

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
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.teal),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                _showNewChatDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.teal),
              title: const Text('New Group'),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewChatPage(),
        settings: const RouteSettings(name: '/new_chat'),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupPage(),
        settings: const RouteSettings(name: '/create_group'),
      ),
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
                settings: const RouteSettings(name: '/group_chat'),
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
          color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
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
              color: unreadCount > 0 ? Colors.teal : Colors.grey[600],
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(10),
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
              color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
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
              color: unreadCount > 0 ? Colors.teal : Colors.grey[600],
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(10),
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
