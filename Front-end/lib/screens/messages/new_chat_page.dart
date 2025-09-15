import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'create_group_page.dart';
import '../../services/message_service.dart';
import '../../models/user_model.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  Set<int> _creatingChatUserIds = {}; // Track which users are currently being processed
  String? _errorMessage;
  
  // Filter states
  String? _selectedDepartment;
  String? _selectedDesignation;
  int? _selectedLevel;
  String? _selectedSession;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _messageService.searchUsers();
      
      if (result['success']) {
        final users = (result['users'] as List)
            .map((user) => UserModel.fromJson(user))
            .toList();
        
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load users';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading users: $e';
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final searchTerm = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        // Text search filter
        bool matchesSearch = searchTerm.isEmpty ||
            user.name.toLowerCase().contains(searchTerm) ||
            user.email.toLowerCase().contains(searchTerm) ||
            (user.designation?.toLowerCase().contains(searchTerm) ?? false);
        
        // Department filter
        bool matchesDepartment = _selectedDepartment == null || 
            user.department == _selectedDepartment;
        
        // Designation filter
        bool matchesDesignation = _selectedDesignation == null || 
            user.designation == _selectedDesignation;
        
        // Level filter
        bool matchesLevel = _selectedLevel == null || 
            user.level == _selectedLevel;
        
        // Session filter
        bool matchesSession = _selectedSession == null || 
            user.session == _selectedSession;
        
        return matchesSearch && matchesDepartment && matchesDesignation && 
               matchesLevel && matchesSession;
      }).toList();
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedDepartment = null;
      _selectedDesignation = null;
      _selectedLevel = null;
      _selectedSession = null;
    });
    _filterUsers();
  }
  
  // Get unique values for filter dropdowns
  List<String> get _departments => _allUsers
      .where((user) => user.department != null)
      .map((user) => user.department!)
      .toSet()
      .toList()..sort();
  
  List<String> get _designations => _allUsers
      .where((user) => user.designation != null)
      .map((user) => user.designation!)
      .toSet()
      .toList()..sort();
  
  List<int> get _levels => _allUsers
      .where((user) => user.level != null)
      .map((user) => user.level!)
      .toSet()
      .toList()..sort();
  
  List<String> get _sessions => _allUsers
      .where((user) => user.session != null)
      .map((user) => user.session!)
      .toSet()
      .toList()..sort();

  Future<void> _startChat(UserModel user) async {
    if (_creatingChatUserIds.contains(user.id)) return;

    setState(() {
      _creatingChatUserIds.add(user.id);
    });

    try {
      final result = await _messageService.createConversation(
        type: 'individual',
        participantIds: [user.id],
      );

      if (result['success']) {
        final conversationId = result['conversation']['id'];
        if (mounted) {
          Navigator.pop(context); // Go back to messages page first
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversationId,
                contactName: user.name,
                avatar: user.avatar,
                isOnline: user.isOnline,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _creatingChatUserIds.remove(user.id);
        });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupPage(),
                ),
              );
            },
            tooltip: 'Create Group',
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
                        onPressed: _loadUsers,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar and Filters
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search field
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name or email...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.filter_list,
                                      color: _showFilters ? Colors.teal : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showFilters = !_showFilters;
                                      });
                                    },
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _searchController.clear(),
                                    ),
                                ],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          
                          // Filter options
                          if (_showFilters) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.filter_alt, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Filters',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: _clearFilters,
                                          child: const Text('Clear All'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Department filter
                                    DropdownButtonFormField<String>(
                                      value: _selectedDepartment,
                                      decoration: const InputDecoration(
                                        labelText: 'Department',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('All Departments'),
                                        ),
                                        ..._departments.map((dept) => DropdownMenuItem(
                                          value: dept,
                                          child: Text(dept),
                                        )),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDepartment = value;
                                        });
                                        _filterUsers();
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Designation filter
                                    DropdownButtonFormField<String>(
                                      value: _selectedDesignation,
                                      decoration: const InputDecoration(
                                        labelText: 'Role/Designation',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('All Roles'),
                                        ),
                                        ..._designations.map((designation) => DropdownMenuItem(
                                          value: designation,
                                          child: Text(designation),
                                        )),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDesignation = value;
                                        });
                                        _filterUsers();
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      children: [
                                        // Level filter
                                        Expanded(
                                          child: DropdownButtonFormField<int>(
                                            value: _selectedLevel,
                                            decoration: const InputDecoration(
                                              labelText: 'Level',
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            items: [
                                              const DropdownMenuItem<int>(
                                                value: null,
                                                child: Text('All Levels'),
                                              ),
                                              ..._levels.map((level) => DropdownMenuItem(
                                                value: level,
                                                child: Text('Level $level'),
                                              )),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedLevel = value;
                                              });
                                              _filterUsers();
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Session filter
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedSession,
                                            decoration: const InputDecoration(
                                              labelText: 'Session',
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            items: [
                                              const DropdownMenuItem<String>(
                                                value: null,
                                                child: Text('All Sessions'),
                                              ),
                                              ..._sessions.map((session) => DropdownMenuItem(
                                                value: session,
                                                child: Text(session),
                                              )),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedSession = value;
                                              });
                                              _filterUsers();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Results count
                    if (_filteredUsers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.person_search, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(
                              'Found ${_filteredUsers.length} user${_filteredUsers.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const Spacer(),
                            if (_searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: _clearFilters,
                                child: const Text('Clear'),
                              ),
                          ],
                        ),
                      ),
                    
                    // Users list
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No users found matching your search'
                                        : 'No users available',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchController.text.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _clearFilters,
                                      child: const Text('Clear search'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return UserTile(
                                  user: user,
                                  isCreatingChat: _creatingChatUserIds.contains(user.id),
                                  onTap: () => _startChat(user),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class UserTile extends StatelessWidget {
  final UserModel user;
  final bool isCreatingChat;
  final VoidCallback onTap;

  const UserTile({
    Key? key,
    required this.user,
    required this.isCreatingChat,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            
            // Role/Designation
            if (user.designation != null)
              Row(
                children: [
                  Icon(Icons.work_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.designation!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            
            // Department
            if (user.department != null)
              Row(
                children: [
                  Icon(Icons.business_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.department!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            
            // Level and Session
            if (user.level != null || user.session != null)
              Row(
                children: [
                  if (user.level != null) ...[
                    Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${user.level}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (user.level != null && user.session != null)
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  if (user.session != null) ...[
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      user.session!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
        trailing: isCreatingChat
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chat_bubble_outline),
        onTap: isCreatingChat ? null : onTap,
      ),
    );
  }
}
