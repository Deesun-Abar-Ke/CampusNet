import 'package:flutter/material.dart';
import 'chat_screen.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filter options
  String _selectedSortOption = 'name'; // 'name', 'department', 'level', 'session'
  String _selectedDepartment = 'all';
  String _selectedLevel = 'all';
  String _selectedSession = 'all';
  
  final List<ChatUser> allUsers = [
    ChatUser(id: '1', name: 'Rakib Ahmed', avatar: '👨‍🎓', isOnline: true, department: 'Computer Science', studentId: '190204001', level: 'Level 4', session: '2020-21'),
    ChatUser(id: '2', name: 'Sarah Khan', avatar: '👩‍💻', isOnline: false, department: 'Computer Science', studentId: '190204002', level: 'Level 4', session: '2020-21'),
    ChatUser(id: '3', name: 'Ahmed Hassan', avatar: '👨‍🔬', isOnline: true, department: 'Chemical Engineering', studentId: '210204003', level: 'Level 3', session: '2021-22'),
    ChatUser(id: '4', name: 'Nadia Rahman', avatar: '👩‍🎓', isOnline: true, department: 'Architecture', studentId: '190404004', level: 'Level 4', session: '2020-21'),
    ChatUser(id: '5', name: 'Karim Uddin', avatar: '👨‍💼', isOnline: false, department: 'Computer Science', studentId: '220204005', level: 'Level 2', session: '2022-23'),
    ChatUser(id: '6', name: 'Fatima Islam', avatar: '👩‍🔬', isOnline: true, department: 'Electrical Engineering', studentId: '230204006', level: 'Level 3', session: '2021-22'),
  ];

  List<ChatUser> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    filteredUsers = allUsers;
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    setState(() {
      List<ChatUser> filtered = allUsers;
      
      // Apply text search filter
      if (_searchController.text.isNotEmpty) {
        filtered = filtered
            .where((user) =>
                user.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.department.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.studentId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.level.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.session.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      }
      
      // Apply department filter
      if (_selectedDepartment != 'all') {
        filtered = filtered.where((user) => user.department == _selectedDepartment).toList();
      }
      
      // Apply level filter
      if (_selectedLevel != 'all') {
        filtered = filtered.where((user) => user.level == _selectedLevel).toList();
      }
      
      // Apply session filter
      if (_selectedSession != 'all') {
        filtered = filtered.where((user) => user.session == _selectedSession).toList();
      }
      
      // Apply sorting
      if (_selectedSortOption == 'name') {
        filtered.sort((a, b) => a.name.compareTo(b.name));
      } else if (_selectedSortOption == 'department') {
        filtered.sort((a, b) => a.department.compareTo(b.department));
      } else if (_selectedSortOption == 'level') {
        filtered.sort((a, b) => a.level.compareTo(b.level));
      } else if (_selectedSortOption == 'session') {
        filtered.sort((a, b) => a.session.compareTo(b.session));
      }
      
      filteredUsers = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSortOption = 'name';
      _selectedDepartment = 'all';
      _selectedLevel = 'all';
      _selectedSession = 'all';
      _searchController.clear();
      _filterUsers();
    });
  }

  List<String> get _departments {
    return ['all', ...allUsers.map((user) => user.department).toSet().toList()..sort()];
  }

  List<String> get _levels {
    return ['all', ...allUsers.map((user) => user.level).toSet().toList()..sort()];
  }

  List<String> get _sessions {
    return ['all', ...allUsers.map((user) => user.session).toSet().toList()..sort()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text(
          'New Chat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, department, or ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Filter and Sort Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // First Row: Status and Sort
                Row(
                  children: [
                    // Sort Options only
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSortOption,
                        decoration: InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'department', child: Text('Department')),
                          DropdownMenuItem(value: 'level', child: Text('Level')),
                          DropdownMenuItem(value: 'session', child: Text('Session')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSortOption = value!;
                            _filterUsers();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second Row: Department, Level, Session
                Row(
                  children: [
                    // Department Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: InputDecoration(
                          labelText: 'Dept',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                        items: _departments.map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(
                            dept == 'all' ? 'All' : dept,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value!;
                            _filterUsers();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Level Filter
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Lvl',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                        items: _levels.map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(
                            level == 'all' ? 'All' : level,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLevel = value!;
                            _filterUsers();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Session Filter
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedSession,
                        decoration: InputDecoration(
                          labelText: 'Sess',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                        items: _sessions.map((session) => DropdownMenuItem(
                          value: session,
                          child: Text(
                            session == 'all' ? 'All' : session,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSession = value!;
                            _filterUsers();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredUsers.length} user(s) found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_searchController.text.isNotEmpty || _selectedDepartment != 'all' || _selectedLevel != 'all' || _selectedSession != 'all')
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal[100],
                                child: Text(
                                  user.avatar,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              if (user.isOnline)
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
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.department),
                              Text(
                                '${user.level} • ${user.session}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'ID: ${user.studentId}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    contactName: user.name,
                                    avatar: user.avatar,
                                    isOnline: user.isOnline,
                                  ),
                                  settings: const RouteSettings(name: '/chat'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChatUser {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;
  final String department;
  final String studentId;
  final String level;
  final String session;

  ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
    required this.department,
    required this.studentId,
    required this.level,
    required this.session,
  });
}
