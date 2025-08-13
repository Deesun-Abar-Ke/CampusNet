import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../study_materials/group_resources_page.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/reference_message_bubble.dart';
import '../profile_page.dart';
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
              subtitle: const Text('Chat with someone new'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewChatPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.teal),
              title: const Text('Create Group'),
              subtitle: const Text('Start a group conversation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateGroupPage()),
                );
              },
            ),
          ],
        ),
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
  String selectedDepartment = 'All';
  String selectedBatch = 'All';
  String selectedLevel = 'All';
  
  final List<Map<String, dynamic>> allUsers = [
    {
      'name': 'Rakib Ahmed', 
      'avatar': '👨‍🎓', 
      'isOnline': true,
      'studentId': '190204001',
      'department': 'Computer Science',
      'batch': '2020',
      'phone': '+8801712345678',
      'level': 'Level 4'
    },
    {
      'name': 'Sarah Khan', 
      'avatar': '👩‍💻', 
      'isOnline': false,
      'studentId': '190204002',
      'department': 'Computer Science',
      'batch': '2020',
      'phone': '+8801798765432',
      'level': 'Level 4'
    },
    {
      'name': 'Ahmed Hassan', 
      'avatar': '👨‍🔬', 
      'isOnline': true,
      'studentId': '210204003',
      'department': 'Chemical Engineering',
      'batch': '2021',
      'phone': '+8801612345678',
      'level': 'Level 3'
    },
    {
      'name': 'Nadia Rahman', 
      'avatar': '👩‍🎓', 
      'isOnline': true,
      'studentId': '190404004',
      'department': 'Architecture',
      'batch': '2019',
      'phone': '+8801534567890',
      'level': 'Level 4'
    },
    {
      'name': 'Karim Uddin', 
      'avatar': '👨‍💼', 
      'isOnline': false,
      'studentId': '220204005',
      'department': 'Computer Science',
      'batch': '2022',
      'phone': '+8801687654321',
      'level': 'Level 2'
    },
    {
      'name': 'Fatima Islam', 
      'avatar': '👩‍🔬', 
      'isOnline': true,
      'studentId': '230204006',
      'department': 'Electrical Engineering',
      'batch': '2023',
      'phone': '+8801543210987',
      'level': 'Level 1'
    },
  ];

  List<String> get departments => ['All', ...allUsers.map((user) => user['department']).toSet()];
  List<String> get batches => ['All', ...allUsers.map((user) => user['batch']).toSet().toList()..sort()];
  List<String> get levels => ['All', 'Level 1', 'Level 2', 'Level 3', 'Level 4'];

  List<Map<String, dynamic>> get filteredUsers {
    return allUsers.where((user) {
      final matchesSearch = user['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                           user['studentId'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                           user['phone'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesDepartment = selectedDepartment == 'All' || user['department'] == selectedDepartment;
      final matchesBatch = selectedBatch == 'All' || user['batch'] == selectedBatch;
      final matchesLevel = selectedLevel == 'All' || user['level'] == selectedLevel;
      
      return matchesSearch && matchesDepartment && matchesBatch && matchesLevel;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start New Chat'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or phone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
            const SizedBox(height: 8),
            
            // Filter Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Dept',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    items: departments.map((dept) => DropdownMenuItem(
                      value: dept,
                      child: Text(
                        dept == 'All' ? 'All' : dept.split(' ').first,
                        style: const TextStyle(fontSize: 12),
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedDepartment = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: const InputDecoration(
                      labelText: 'Batch',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    items: batches.map((batch) => DropdownMenuItem(
                      value: batch,
                      child: Text(batch, style: const TextStyle(fontSize: 12)),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedBatch = value!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    items: levels.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level, style: const TextStyle(fontSize: 12)),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedLevel = value!),
                  ),
                ),
              ],
            ),
            
            Text('${filteredUsers.length} students found', 
                 style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            
            Expanded(
              child: ListView.builder(
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
                    subtitle: Text('${user['studentId']} • ${user['department'].split(' ').first} • Batch ${user['batch']}'),
                    trailing: Text(user['isOnline'] ? 'Online' : 'Offline', 
                                   style: TextStyle(
                                     color: user['isOnline'] ? Colors.green : Colors.grey,
                                     fontSize: 12
                                   )),
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
  final List<String> selectedMembers = [];
  String searchQuery = '';
  String selectedDepartment = 'All';
  String selectedBatch = 'All';
  String selectedLevel = 'All';

  final List<Map<String, dynamic>> allUsers = [
    {
      'name': 'Rakib Ahmed', 
      'avatar': '👨‍🎓',
      'studentId': '190204001',
      'department': 'Computer Science & Engineering',
      'batch': '2020',
      'phone': '+8801712345678',
      'level': 'Level 4'
    },
    {
      'name': 'Sarah Khan', 
      'avatar': '👩‍💻',
      'studentId': '190204002',
      'department': 'Computer Science & Engineering',
      'batch': '2020',
      'phone': '+8801798765432',
      'level': 'Level 4'
    },
    {
      'name': 'Ahmed Hassan', 
      'avatar': '👨‍🔬',
      'studentId': '210204003',
      'department': 'Chemical Engineering',
      'batch': '2021',
      'phone': '+8801612345678',
      'level': 'Level 3'
    },
    {
      'name': 'Nadia Rahman', 
      'avatar': '👩‍🎓',
      'studentId': '190404004',
      'department': 'Architecture',
      'batch': '2019',
      'phone': '+8801534567890',
      'level': 'Level 4'
    },
    {
      'name': 'Karim Uddin', 
      'avatar': '👨‍💼',
      'studentId': '220204005',
      'department': 'Computer Science',
      'batch': '2022',
      'phone': '+8801687654321',
      'level': 'Level 2'
    },
  ];

  List<String> get departments => ['All', ...allUsers.map((user) => user['department']).toSet()];
  List<String> get batches => ['All', ...allUsers.map((user) => user['batch']).toSet().toList()..sort()];
  List<String> get levels => ['All', 'Level 1', 'Level 2', 'Level 3', 'Level 4'];

  List<Map<String, dynamic>> get filteredUsers {
    return allUsers.where((user) {
      final matchesSearch = user['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                           user['studentId'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                           user['phone'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesDepartment = selectedDepartment == 'All' || user['department'] == selectedDepartment;
      final matchesBatch = selectedBatch == 'All' || user['batch'] == selectedBatch;
      final matchesLevel = selectedLevel == 'All' || user['level'] == selectedLevel;
      
      return matchesSearch && matchesDepartment && matchesBatch && matchesLevel;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Group'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: 500,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
            const SizedBox(height: 12),
            
            // Search Field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or phone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
            const SizedBox(height: 8),
            
            // Filter Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Dept',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                    items: departments.map((dept) => DropdownMenuItem(
                      value: dept,
                      child: Text(dept == 'All' ? 'All' : dept.split(' ').first, 
                                  style: const TextStyle(fontSize: 11)),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedDepartment = value!),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: const InputDecoration(
                      labelText: 'Batch',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                    items: batches.map((batch) => DropdownMenuItem(
                      value: batch,
                      child: Text(batch, style: const TextStyle(fontSize: 11)),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedBatch = value!),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                    items: levels.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level, style: const TextStyle(fontSize: 11)),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedLevel = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Members (${selectedMembers.length} selected):', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${filteredUsers.length} found', 
                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
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
                    title: Text(user['name']),
                    subtitle: Text('${user['studentId']} • ${user['department'].split(' ').first} • Batch ${user['batch']}',
                                   style: const TextStyle(fontSize: 12)),
                    trailing: CircleAvatar(
                      backgroundColor: Colors.teal[100],
                      radius: 16,
                      child: Text(user['avatar'], style: const TextStyle(fontSize: 12)),
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
          onPressed: groupName.isNotEmpty && selectedMembers.length >= 2
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              } else if (value == 'clear') {
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
                  color: const Color(0xFF25D366), // WhatsApp green-like
                  onTap: () => _handleCameraSelection(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: const Color(0xFF128C7E), // Darker teal
                  onTap: () => _handleGallerySelection(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.description,
                  label: 'Document',
                  color: const Color(0xFF075E54), // Dark teal
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
        // Add the image message to chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo captured: ${image.name}')),
        );
        // Here you would add the image to your message list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
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
        // Add the image message to chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selected: ${image.name}')),
        );
        // Here you would add the image to your message list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _handleDocumentSelection(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document selected: ${file.name}')),
        );
        // Here you would add the document to your message list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting document: $e')),
      );
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
                    offset: const Offset(0, 4),
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
}

class GroupChatScreen extends StatefulWidget {
  final String groupName;
  final int memberCount;
  final String avatar;
  final String courseFolder;
  final String currentUserId;

  const GroupChatScreen({
    super.key,
    required this.groupName,
    required this.memberCount,
    required this.avatar,
    required this.courseFolder,
    this.currentUserId = 'current_user',
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
    {
      'text': 'I have uploaded all files for upcoming CT here is the reference',
      'sender': 'Prof. Rahman',
      'isMe': false,
      'time': '3:50 PM',
      'type': 'text',
    },
    {
      'text': '📎 Resource Reference: CT2',
      'reference': 'CT2 Folder - Contains exam materials\nUploaded materials for upcoming CT exam',
      'sender': 'Prof. Rahman',
      'isMe': false,
      'time': '3:48 PM',
      'type': 'reference',
      'folderPath': ['SecA', 'CT2'], // Path to the folder
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupResourcesPage(
                      groupName: widget.groupName,
                    ),
                  ),
                );
              },
              tooltip: 'Group Resources',
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
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
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
            onSelected: (value) {
              switch (value) {
                case 'resources':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupResourcesPage(
                        groupName: widget.groupName,
                      ),
                    ),
                  );
                  break;
                case 'members':
                  _showMembersDialog(context);
                  break;
                case 'add_member':
                  _showAddMemberDialog(context);
                  break;
                case 'search':
                  _showSearchDialog(context);
                  break;
                case 'clear':
                  _showClearChatDialog(context);
                  break;
                case 'leave':
                  _showLeaveGroupDialog(context);
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
                if (message['type'] == 'reference') {
                  return ReferenceMessageBubble(
                    text: message['text'],
                    reference: message['reference'] ?? '',
                    sender: message['sender'],
                    isMe: message['isMe'],
                    time: message['time'],
                    folderPath: message['folderPath'],
                  );
                } else {
                  return GroupMessageBubble(
                    text: message['text'],
                    sender: message['sender'],
                    isMe: message['isMe'],
                    time: message['time'],
                    currentUserId: widget.currentUserId,
                  );
                }
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
      {'name': 'Prof. Rahman', 'role': 'Admin', 'avatar': '👨‍🏫', 'studentId': '190101001'},
      {'name': 'You', 'role': 'Member', 'avatar': '👨‍🎓', 'studentId': '190204002'},
      {'name': 'Ahmed Hassan', 'role': 'Member', 'avatar': '👨‍🔬', 'studentId': '210204003'},
      {'name': 'Sarah Khan', 'role': 'Member', 'avatar': '👩‍💻', 'studentId': '190204004'},
      {'name': 'Nadia Rahman', 'role': 'Member', 'avatar': '👩‍🎓', 'studentId': '190404005'},
      {'name': 'Karim Uddin', 'role': 'Member', 'avatar': '👨‍💼', 'studentId': '220204006'},
      {'name': 'Fatima Islam', 'role': 'Member', 'avatar': '👩‍🔬', 'studentId': '230204007'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('${widget.groupName} Members'),
            const Spacer(),
            Text('${members.length}', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isCurrentUser = member['name'] == 'You';
              final isAdmin = member['role'] == 'Admin';
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: Text(member['avatar']!),
                  ),
                  title: Row(
                    children: [
                      Text(member['name']!),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal[600],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text('ID: ${member['studentId']}'),
                  trailing: isCurrentUser 
                    ? null 
                    : PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'chat',
                            child: Row(
                              children: [
                                Icon(Icons.chat, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text('Personal Chat'),
                              ],
                            ),
                          ),
                          if (!isAdmin) // Can't remove admin
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(Icons.person_remove, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Remove Member'),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (value) {
                          if (value == 'chat') {
                            _openPersonalChat(context, member);
                          } else if (value == 'remove') {
                            _showRemoveMemberConfirmation(context, member);
                          }
                        },
                      ),
                ),
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

  void _showGroupInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal[100],
                  child: Text(widget.avatar, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('${widget.memberCount} members'),
                      Text('Created ${DateTime.now().subtract(const Duration(days: 30)).day}/${DateTime.now().subtract(const Duration(days: 30)).month}/${DateTime.now().subtract(const Duration(days: 30)).year}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Study group for Computer Science students. Share notes, assignments, and discuss course material.'),
          ],
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

  void _showAddMemberDialog(BuildContext context) {
    String searchQuery = '';
    String selectedDepartment = 'All';
    String selectedBatch = 'All';
    String selectedLevel = 'All';
    final List<String> selectedMembers = [];
    
    final List<Map<String, dynamic>> availableUsers = [
      {'name': 'Rakib Ahmed', 'avatar': '👨‍🎓', 'studentId': '190204001', 'department': 'Computer Science & Engineering', 'batch': '2020', 'level': 'Level 4'},
      {'name': 'Fatima Islam', 'avatar': '👩‍🔬', 'studentId': '230204006', 'department': 'Electrical Engineering', 'batch': '2023', 'level': 'Level 1'},
      {'name': 'Karim Uddin', 'avatar': '👨‍💼', 'studentId': '220204005', 'department': 'Computer Science & Engineering', 'batch': '2022', 'level': 'Level 2'},
      {'name': 'Samiya Hasan', 'avatar': '👩‍💼', 'studentId': '210204007', 'department': 'Chemical Engineering', 'batch': '2021', 'level': 'Level 3'},
      {'name': 'Mariam Khan', 'avatar': '👩‍🎓', 'studentId': '190404008', 'department': 'Architecture', 'batch': '2019', 'level': 'Level 4'},
      {'name': 'Omar Hassan', 'avatar': '👨‍🔬', 'studentId': '210204009', 'department': 'Chemical Engineering', 'batch': '2021', 'level': 'Level 3'},
    ];

    List<String> departments = ['All', ...availableUsers.map((user) => user['department']).toSet()];
    List<String> batches = ['All', ...availableUsers.map((user) => user['batch']).toSet().toList()..sort()];
    List<String> levels = ['All', 'Level 1', 'Level 2', 'Level 3', 'Level 4'];

    List<Map<String, dynamic>> getFilteredUsers() {
      return availableUsers.where((user) {
        final matchesSearch = user['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                             user['studentId'].toLowerCase().contains(searchQuery.toLowerCase());
        final matchesDepartment = selectedDepartment == 'All' || user['department'] == selectedDepartment;
        final matchesBatch = selectedBatch == 'All' || user['batch'] == selectedBatch;
        final matchesLevel = selectedLevel == 'All' || user['level'] == selectedLevel;
        
        return matchesSearch && matchesDepartment && matchesBatch && matchesLevel;
      }).toList();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Members'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 500,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                // Search Field
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 12),
                
                // Filter Row 1
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (value) => setState(() => selectedDepartment = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedBatch,
                        decoration: const InputDecoration(
                          labelText: 'Batch',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: batches.map((batch) => DropdownMenuItem(value: batch, child: Text(batch, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (value) => setState(() => selectedBatch = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Filter Row 2
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedLevel,
                        decoration: const InputDecoration(
                          labelText: 'Level',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: levels.map((level) => DropdownMenuItem(value: level, child: Text(level, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (value) => setState(() => selectedLevel = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${selectedMembers.length} selected',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
                
                Text('${getFilteredUsers().length} students found', 
                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: getFilteredUsers().length,
                    itemBuilder: (context, index) {
                      final user = getFilteredUsers()[index];
                      final isSelected = selectedMembers.contains(user['name']);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[100],
                            child: Text(user['avatar'], style: const TextStyle(fontSize: 16)),
                          ),
                          title: Text(user['name'], style: const TextStyle(fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${user['studentId']}', style: const TextStyle(fontSize: 11)),
                              Text('${user['department']} - ${user['level']}', style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedMembers.add(user['name']);
                                } else {
                                  selectedMembers.remove(user['name']);
                                }
                              });
                            },
                          ),
                        ),
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
              onPressed: selectedMembers.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${selectedMembers.length} members to ${widget.groupName}')),
                      );
                    }
                  : null,
              child: const Text('Add Members'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaFilesDialog(BuildContext context) {
    final mediaFiles = [
      {'name': 'Assignment_2.pdf', 'type': 'PDF', 'size': '2.4 MB', 'date': 'Yesterday'},
      {'name': 'Lecture_Notes.docx', 'type': 'DOC', 'size': '1.2 MB', 'date': '2 days ago'},
      {'name': 'Group_Photo.jpg', 'type': 'IMG', 'size': '3.1 MB', 'date': '1 week ago'},
      {'name': 'Study_Material.zip', 'type': 'ZIP', 'size': '15.6 MB', 'date': '2 weeks ago'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media & Files'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: mediaFiles.length,
            itemBuilder: (context, index) {
              final file = mediaFiles[index];
              IconData fileIcon;
              Color iconColor;
              
              switch (file['type']) {
                case 'PDF':
                  fileIcon = Icons.picture_as_pdf;
                  iconColor = Colors.red;
                  break;
                case 'DOC':
                  fileIcon = Icons.description;
                  iconColor = Colors.blue;
                  break;
                case 'IMG':
                  fileIcon = Icons.image;
                  iconColor = Colors.green;
                  break;
                case 'ZIP':
                  fileIcon = Icons.archive;
                  iconColor = Colors.orange;
                  break;
                default:
                  fileIcon = Icons.insert_drive_file;
                  iconColor = Colors.grey;
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(fileIcon, color: iconColor),
                ),
                title: Text(file['name']!),
                subtitle: Text('${file['size']} • ${file['date']}'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'download', child: Text('Download')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
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

  void _toggleNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mute Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('8 hours'),
              onTap: () => _muteForDuration(context, '8 hours'),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('1 day'),
              onTap: () => _muteForDuration(context, '1 day'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('1 week'),
              onTap: () => _muteForDuration(context, '1 week'),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Until I turn it back on'),
              onTap: () => _muteForDuration(context, 'forever'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _muteForDuration(BuildContext context, String duration) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Group muted for $duration')),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                messages.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${widget.groupName}"? You won\'t be able to see new messages unless someone adds you back.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to messages list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Left ${widget.groupName}')),
              );
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openPersonalChat(BuildContext context, Map<String, dynamic> member) {
    Navigator.pop(context); // Close members dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          contactName: member['name'],
          avatar: member['avatar'],
          isOnline: true, // You can implement actual online status
        ),
      ),
    );
  }

  void _showRemoveMemberConfirmation(BuildContext context, Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member['name']} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close members dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member['name']} removed from group')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
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
}

class GroupMessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  final String time;
  final String currentUserId;

  const GroupMessageBubble({
    super.key,
    required this.text,
    required this.sender,
    required this.isMe,
    required this.time,
    required this.currentUserId,
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
          isOnline: true,
        ),
      ),
    );
  }
}
