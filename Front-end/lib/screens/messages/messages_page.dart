import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import '../../services/message_service.dart';
import '../../services/current_user_service.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'new_chat_page.dart';
import 'create_group_page.dart';

class MessagesPage extends StatefulWidget {
  final String? initialContact;
  final String? initialMessage;

  const MessagesPage({
    super.key,
    this.initialContact,
    this.initialMessage,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  Key _individualChatsKey = UniqueKey();
  Key _groupChatsKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    
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
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh conversations when app comes back to foreground
      _refreshCurrentTab();
    }
  }

  void _refreshCurrentTab() {
    // Force refresh by generating new keys for the tabs
    // This will cause the tabs to rebuild and reload their data
    if (mounted) {
      setState(() {
        _individualChatsKey = UniqueKey();
        _groupChatsKey = UniqueKey();
      });
    }
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
              children: [
                IndividualChatsTab(key: _individualChatsKey),
                GroupChatsTab(key: _groupChatsKey),
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
    ).then((_) {
      // Refresh when returning from new chat page
      _refreshCurrentTab();
    });
  }

  void _showCreateGroupDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupPage(),
        settings: const RouteSettings(name: '/create_group'),
      ),
    ).then((_) {
      // Refresh when returning from create group page
      _refreshCurrentTab();
    });
  }
}

class IndividualChatsTab extends StatefulWidget {
  const IndividualChatsTab({super.key});

  @override
  State<IndividualChatsTab> createState() => _IndividualChatsTabState();
}

class _IndividualChatsTabState extends State<IndividualChatsTab> {
  final MessageService _messageService = MessageService();
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _messageService.getConversations();
      
      if (!mounted) return; // Check again after async operation
      
      if (result['success']) {
        final conversations = (result['conversations'] as List)
            .map((conv) => ConversationModel.fromJson(conv))
            .where((conv) => conv.type == 'individual') // Only show individual chats
            .toList();
        
        // Get current user info for filtering
        final currentUserId = CurrentUserService.getCurrentUserId();
        final currentUserName = CurrentUserService.getCurrentUserName();
        
        print('DEBUG - Current User: ID=$currentUserId, Name=$currentUserName');
        
        // Debug: Print conversation data to see what's being returned
        for (var conv in conversations) {
          print('DEBUG - Individual Chat: ID=${conv.id}, Name="${conv.name}", Type=${conv.type}');
          
          // Find the OTHER participant (not current user)
          String? otherParticipantName;
          for (var participant in conv.participants) {
            print('  Participant: ${participant.name} (ID: ${participant.id})');
            if (participant.id != currentUserId) {
              otherParticipantName = participant.name;
              print('  -> OTHER PARTICIPANT: $otherParticipantName');
            }
          }
          
          // If conversation name is null or equals current user, use other participant name
          if (conv.name == null || conv.name == currentUserName || conv.name == 'moon') {
            conv = ConversationModel(
              id: conv.id,
              name: otherParticipantName ?? 'Unknown User',
              type: conv.type,
              avatar: conv.avatar,
              createdAt: conv.createdAt,
              updatedAt: conv.updatedAt,
              courseFolder: conv.courseFolder,
              unreadCount: conv.unreadCount,
              lastMessage: conv.lastMessage,
              participants: conv.participants,
              memberCount: conv.memberCount,
            );
            print('  -> FIXED NAME TO: ${conv.name}');
          }
        }
        
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load conversations';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _errorMessage = 'Error loading conversations: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              onPressed: _loadConversations,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat to begin messaging',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: Colors.teal,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          
          // For individual chats, use the conversation name set by backend
          // For group chats, use the conversation name as well
          String displayName;
          String displayAvatar;
          bool isOnline = false;
          
          if (conversation.type == 'individual') {
            // For individual chats, backend should have set the name to the other participant
            displayName = conversation.name ?? 'Unknown User';
            displayAvatar = conversation.avatar;
            
            // Try to get online status from participants
            for (var participant in conversation.participants) {
              // Find the participant who is not the current user (will need current user ID)
              if (participant.name == displayName) {
                isOnline = participant.isOnline;
                break;
              }
            }
          } else {
            // For group chats, use conversation name and avatar
            displayName = conversation.name ?? 'Group Chat';
            displayAvatar = conversation.avatar;
          }
          
          return ChatTile(
            name: displayName,
            lastMessage: conversation.lastMessage?.content ?? 'No messages yet',
            time: _formatTime(conversation.lastMessage?.sentAt ?? conversation.updatedAt),
            unreadCount: conversation.unreadCount,
            avatar: displayAvatar,
            isOnline: isOnline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    conversationId: conversation.id,
                    contactName: displayName,
                    avatar: displayAvatar,
                    isOnline: isOnline,
                  ),
                ),
              ).then((_) {
                if (mounted) _loadConversations(); // Safe async call
              }); // Refresh when returning
            },
          );
        },
      ),
    );
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '';
    }
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}

class GroupChatsTab extends StatefulWidget {
  const GroupChatsTab({super.key});

  @override
  State<GroupChatsTab> createState() => _GroupChatsTabState();
}

class _GroupChatsTabState extends State<GroupChatsTab> {
  final MessageService _messageService = MessageService();
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _messageService.getConversations();
      
      if (!mounted) return; // Check again after async operation
      
      if (result['success']) {
        final conversations = (result['conversations'] as List)
            .map((conv) => ConversationModel.fromJson(conv))
            .where((conv) => conv.type == 'group')
            .toList();
        
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load conversations';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _errorMessage = 'Error loading conversations: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              onPressed: _loadConversations,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No group chats yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to start collaborating',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: Colors.teal,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          
          return GroupTile(
            name: conversation.name ?? 'Unnamed Group',
            lastMessage: conversation.lastMessage?.content ?? 'No messages yet',
            time: _formatTime(conversation.lastMessage?.sentAt ?? conversation.updatedAt),
            unreadCount: conversation.unreadCount,
            memberCount: conversation.memberCount,
            avatar: conversation.avatar,
            courseFolder: conversation.courseFolder ?? '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(
                    conversationId: conversation.id,
                    groupName: conversation.name ?? 'Unnamed Group',
                    memberCount: conversation.memberCount,
                    avatar: conversation.avatar,
                    courseFolder: conversation.courseFolder ?? '',
                  ),
                  settings: const RouteSettings(name: '/group_chat'),
                ),
              ).then((_) {
                if (mounted) _loadConversations(); // Safe async call
              }); // Refresh when returning
            },
          );
        },
      ),
    );
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '';
    }
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
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
