import 'package:flutter/material.dart';
import 'group_chat_screen.dart';
import '../../services/message_service.dart';
import '../../models/user_model.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final MessageService _messageService = MessageService();
  final List<UserModel> _selectedUsers = [];
  
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  bool _isCreatingGroup = false;
  String? _errorMessage;
  
  // Filter states
  String? _selectedDepartment;
  String? _selectedDesignation;
  String? _selectedLevel;  // Changed to String to match dropdown
  String? _selectedSession;
  bool _showFilters = false;

  // Get unique values for filters
  List<String> get _departments => _allUsers
      .where((user) => user.department != null && user.department!.isNotEmpty)
      .map((user) => user.department!)
      .toSet()
      .toList()..sort();

  List<String> get _designations => _allUsers
      .where((user) => user.designation != null && user.designation!.isNotEmpty)
      .map((user) => user.designation!)
      .toSet()
      .toList()..sort();

  List<String> get _sessions => _allUsers
      .where((user) => user.session != null && user.session!.isNotEmpty)
      .map((user) => user.session!)
      .toSet()
      .toList()..sort();

  List<String> get _levels => _allUsers
      .where((user) => user.level != null)
      .map((user) => user.level.toString())
      .toSet()
      .toList()..sort();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
    _groupNameController.addListener(() {
      setState(() {}); // Rebuild to update FloatingActionButton state
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
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
    
    List<UserModel> filtered = _allUsers.where((user) {
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
          user.level?.toString() == _selectedLevel;
      
      // Session filter
      bool matchesSession = _selectedSession == null || 
          user.session == _selectedSession;
      
      return matchesSearch && matchesDepartment && matchesDesignation && 
             matchesLevel && matchesSession;
    }).toList();

    filtered.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      _filteredUsers = filtered;
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

  Future<void> _createGroup() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isCreatingGroup) return;

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final participantIds = _selectedUsers.map((user) => user.id).toList();
      
      final result = await _messageService.createConversation(
        type: 'group',
        participantIds: participantIds,
        name: _groupNameController.text.trim(),
        avatar: '👥', // Default group avatar
      );

      setState(() {
        _isCreatingGroup = false;
      });

      if (result['success']) {
        final conversationId = result['conversation']['id'];
        // Go back to messages page first, then navigate to group chat
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              conversationId: conversationId,
              groupName: _groupNameController.text.trim(),
              memberCount: _selectedUsers.length + 1, // +1 for current user
              avatar: '👥',
              courseFolder: '',
            ),
          ),
        );
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to create group');
      }
    } catch (e) {
      setState(() {
        _isCreatingGroup = false;
      });
      _showErrorSnackBar('Error creating group: $e');
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

  Widget _buildUserCard(UserModel user) {
    final isSelected = _selectedUsers.any((u) => u.id == user.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
            if (user.designation != null)
              Text(
                user.designation!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            Row(
              children: [
                if (user.department != null) ...[
                  Icon(Icons.business, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Text(
                    user.department!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (user.designation != null) ...[
                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Text(
                    user.designation!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            if (user.session != null || user.level != null)
              Row(
                children: [
                  if (user.session != null) ...[
                    Icon(Icons.school, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Text(
                      'Session: ${user.session}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (user.level != null) ...[
                    Icon(Icons.grade, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Text(
                      'Level: ${user.level}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.add_circle_outline),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedUsers.removeWhere((u) => u.id == user.id);
            } else {
              _selectedUsers.add(user);
            }
          });
        },
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
          'Create Group',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
                // Group name input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'Enter a name for your group',
                      helperText: 'Required to create the group',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.group),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                  ),
                ),
                
                // Search field and filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search users...',
                          border: const OutlineInputBorder(),
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
                                
                                // Department and Designation filters
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
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
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedDesignation,
                                        decoration: const InputDecoration(
                                          labelText: 'Role',
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
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Level and Session filters
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedLevel,
                                        decoration: const InputDecoration(
                                          labelText: 'Level',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('All Levels'),
                                          ),
                                          ..._levels.map((level) => DropdownMenuItem<String>(
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
                
                // Selected users count
                if (_selectedUsers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${_selectedUsers.length} user${_selectedUsers.length != 1 ? 's' : ''} selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
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
                                'No users found',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _selectedUsers.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: _isCreatingGroup 
                  ? Colors.grey 
                  : _groupNameController.text.trim().isEmpty
                      ? Colors.grey
                      : Colors.teal,
              onPressed: _isCreatingGroup || _groupNameController.text.trim().isEmpty 
                  ? null 
                  : _createGroup,
              icon: _isCreatingGroup 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.create, color: Colors.white),
              label: Text(
                _isCreatingGroup 
                    ? 'Creating...' 
                    : _groupNameController.text.trim().isEmpty
                        ? 'Enter Group Name'
                        : 'Create Group',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
