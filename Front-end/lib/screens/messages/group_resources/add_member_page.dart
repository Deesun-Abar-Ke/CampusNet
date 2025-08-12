// lib/screens/messages/group_resources/add_member_page.dart
import 'package:flutter/material.dart';

class AddMemberPage extends StatefulWidget {
  final String groupName;

  const AddMemberPage({
    Key? key,
    required this.groupName,
  }) : super(key: key);

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<User> _selectedUsers = [];
  
  // Filter options
  String _selectedFilter = 'all'; // 'all', 'online', 'offline'
  String _selectedSortOption = 'name'; // 'name', 'department', 'level', 'session'
  String _selectedDepartment = 'all';
  String _selectedLevel = 'all';
  String _selectedSession = 'all';
  
  // Sample user data
  final List<User> _allUsers = [
    User(id: '1', name: 'Alice Johnson', email: 'alice@example.com', phone: '+1234567890', isOnline: true, department: 'Computer Science', level: 'Level 4', session: '2020-21'),
    User(id: '2', name: 'Bob Smith', email: 'bob@example.com', phone: '+1234567891', isOnline: false, department: 'Electrical Engineering', level: 'Level 3', session: '2021-22'),
    User(id: '3', name: 'Charlie Brown', email: 'charlie@example.com', phone: '+1234567892', isOnline: true, department: 'Computer Science', level: 'Level 4', session: '2020-21'),
    User(id: '4', name: 'Diana Prince', email: 'diana@example.com', phone: '+1234567893', isOnline: false, department: 'Architecture', level: 'Level 2', session: '2022-23'),
    User(id: '5', name: 'Edward Norton', email: 'edward@example.com', phone: '+1234567894', isOnline: true, department: 'Civil Engineering', level: 'Level 4', session: '2020-21'),
    User(id: '6', name: 'Fiona Apple', email: 'fiona@example.com', phone: '+1234567895', isOnline: false, department: 'Computer Science', level: 'Level 3', session: '2021-22'),
    User(id: '7', name: 'George Lucas', email: 'george@example.com', phone: '+1234567896', isOnline: true, department: 'Mechanical Engineering', level: 'Level 2', session: '2022-23'),
    User(id: '8', name: 'Hannah Montana', email: 'hannah@example.com', phone: '+1234567897', isOnline: false, department: 'Electrical Engineering', level: 'Level 4', session: '2020-21'),
  ];

  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = _allUsers;
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    setState(() {
      List<User> filtered = _allUsers;
      
      // Apply text search filter
      if (_searchController.text.isNotEmpty) {
        filtered = filtered
            .where((user) =>
                user.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.department.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.level.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.session.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      }
      
      // Apply status filter
      if (_selectedFilter == 'online') {
        filtered = filtered.where((user) => user.isOnline).toList();
      } else if (_selectedFilter == 'offline') {
        filtered = filtered.where((user) => !user.isOnline).toList();
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
      } else if (_selectedSortOption == 'status') {
        filtered.sort((a, b) => b.isOnline.toString().compareTo(a.isOnline.toString()));
      }
      
      _filteredUsers = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'all';
      _selectedSortOption = 'name';
      _selectedDepartment = 'all';
      _selectedLevel = 'all';
      _selectedSession = 'all';
      _searchController.clear();
      _filterUsers();
    });
  }

  List<String> get _departments {
    return ['all', ..._allUsers.map((user) => user.department).toSet().toList()..sort()];
  }

  List<String> get _levels {
    return ['all', ..._allUsers.map((user) => user.level).toSet().toList()..sort()];
  }

  List<String> get _sessions {
    return ['all', ..._allUsers.map((user) => user.session).toSet().toList()..sort()];
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _addSelectedMembers() {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member to add'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Directly add members without popup
    Navigator.pop(context); // Go back to previous page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedUsers.length} member(s) added to ${widget.groupName}'),
        backgroundColor: Colors.green,
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
              onPressed: _addSelectedMembers,
              child: Text(
                'ADD (${_selectedUsers.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
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

          // Filter and Sort Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // First Row: Status and Sort
                Row(
                  children: [
                    // Status Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'online', child: Text('Online')),
                          DropdownMenuItem(value: 'offline', child: Text('Offline')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                            _filterUsers();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort Options
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSortOption,
                        decoration: InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'department', child: Text('Department')),
                          DropdownMenuItem(value: 'level', child: Text('Level')),
                          DropdownMenuItem(value: 'session', child: Text('Session')),
                          DropdownMenuItem(value: 'status', child: Text('Online Status')),
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
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _departments.map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(dept == 'all' ? 'All Departments' : dept),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value!;
                            _filterUsers();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Level Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Level',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _levels.map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level == 'all' ? 'All Levels' : level),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLevel = value!;
                            _filterUsers();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Session Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSession,
                        decoration: InputDecoration(
                          labelText: 'Session',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _sessions.map((session) => DropdownMenuItem(
                          value: session,
                          child: Text(session == 'all' ? 'All Sessions' : session),
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
                  '${_filteredUsers.length} user(s) found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_searchController.text.isNotEmpty || _selectedFilter != 'all' || _selectedDepartment != 'all' || _selectedLevel != 'all' || _selectedSession != 'all')
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),

          // Selected Members Summary
          if (_selectedUsers.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.teal[50],
              child: Text(
                '${_selectedUsers.length} member(s) selected',
                style: TextStyle(
                  color: Colors.teal[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Users List
          Expanded(
            child: _filteredUsers.isEmpty
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
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _selectedUsers.contains(user);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.teal[50] : null,
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal[100],
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.teal[700],
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                user.email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.teal,
                                  size: 28,
                                )
                              : const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                          onTap: () => _toggleUserSelection(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedUsers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addSelectedMembers,
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add ${_selectedUsers.length}',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isOnline;
  final String department;
  final String level;
  final String session;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.level,
    required this.session,
    this.isOnline = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
