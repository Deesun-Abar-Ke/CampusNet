// lib/screens/messages/group_resources/add_member_page.dart
import 'package:flutter/material.dart';
import '../../../services/message_service.dart';
import '../../../models/user_model.dart';

class AddMemberPage extends StatefulWidget {
  final String groupName;
  final int? conversationId;

  const AddMemberPage({
    Key? key,
    required this.groupName,
    this.conversationId,
  }) : super(key: key);

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final List<UserModel> _selectedUsers = [];
  
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<UserModel> _existingMembers = [];
  bool _isLoading = true;
  bool _isAddingMembers = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all users and existing members concurrently
      final usersResult = await _messageService.searchUsers();
      final membersResult = widget.conversationId != null
          ? await _messageService.getConversationParticipants(widget.conversationId!)
          : {'success': true, 'participants': []};

      if (usersResult['success'] && membersResult['success']) {
        final allUsers = (usersResult['users'] as List)
            .map((user) => UserModel.fromJson(user))
            .toList();

        final existingMembers = (membersResult['participants'] as List)
            .map((participant) => UserModel.fromJson(participant))
            .toList();

        // Filter out existing members from the users list
        final availableUsers = allUsers
            .where((user) => !existingMembers.any((member) => member.id == user.id))
            .toList();

        setState(() {
          _allUsers = availableUsers;
          _filteredUsers = availableUsers;
          _existingMembers = existingMembers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = usersResult['message'] ?? membersResult['message'] ?? 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    setState(() {
      List<UserModel> filtered = _allUsers;
      
      // Apply text search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        filtered = filtered
            .where((user) =>
                user.name.toLowerCase().contains(searchTerm) ||
                user.email.toLowerCase().contains(searchTerm) ||
                (user.designation?.toLowerCase().contains(searchTerm) ?? false))
            .toList();
      }
      
      // Sort by name
      filtered.sort((a, b) => a.name.compareTo(b.name));
      
      _filteredUsers = filtered;
    });
  }

  void _toggleUserSelection(UserModel user) {
    setState(() {
      if (_selectedUsers.any((u) => u.id == user.id)) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member to add'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid conversation ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isAddingMembers) return;

    setState(() {
      _isAddingMembers = true;
    });

    try {
      final participantIds = _selectedUsers.map((user) => user.id).toList();
      
      final result = await _messageService.addParticipants(
        widget.conversationId!,
        participantIds,
      );

      setState(() {
        _isAddingMembers = false;
      });

      if (result['success']) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedUsers.length} member(s) added to ${widget.groupName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to add members');
      }
    } catch (e) {
      setState(() {
        _isAddingMembers = false;
      });
      _showErrorSnackBar('Error adding members: $e');
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
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.teal)
            : const Icon(Icons.add_circle_outline, color: Colors.grey),
        onTap: () => _toggleUserSelection(user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.groupName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_selectedUsers.isNotEmpty)
            TextButton(
              onPressed: _isAddingMembers ? null : _addSelectedMembers,
              child: _isAddingMembers
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'ADD (${_selectedUsers.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
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

                    // Selected users count
                    if (_selectedUsers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.group_add, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedUsers.length} user${_selectedUsers.length != 1 ? 's' : ''} selected',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Info about existing members
                    if (_existingMembers.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This group already has ${_existingMembers.length} member${_existingMembers.length != 1 ? 's' : ''}. Only users not already in the group are shown below.',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
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
                                        : 'All users are already members of this group',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchController.text.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterUsers();
                                      },
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
                                return _buildUserCard(user);
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _selectedUsers.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: _isAddingMembers ? Colors.grey : Colors.teal,
              onPressed: _isAddingMembers ? null : _addSelectedMembers,
              icon: _isAddingMembers 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.group_add, color: Colors.white),
              label: Text(
                _isAddingMembers 
                    ? 'Adding...' 
                    : 'Add ${_selectedUsers.length}',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
