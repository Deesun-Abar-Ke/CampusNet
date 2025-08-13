import 'package:flutter/material.dart';
import 'group_chat_screen.dart';

class GroupUser {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;
  final String department;
  final String studentId;
  final String level;
  final String session;

  GroupUser({
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

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final List<GroupUser> _selectedUsers = [];
  
  // Filter options
  String _selectedSortOption = 'name'; // 'name', 'department', 'level', 'session'
  String _selectedDepartment = 'all';
  String _selectedLevel = 'all';
  String _selectedSession = 'all';
  
  final List<GroupUser> allUsers = [
    GroupUser(id: '1', name: 'Rakib Ahmed', avatar: '👨‍🎓', isOnline: true, department: 'Computer Science', studentId: '190204001', level: 'Level 4', session: '2020-21'),
    GroupUser(id: '2', name: 'Sarah Khan', avatar: '👩‍💻', isOnline: false, department: 'Computer Science', studentId: '190204002', level: 'Level 4', session: '2020-21'),
    GroupUser(id: '3', name: 'Ahmed Hassan', avatar: '👨‍🔬', isOnline: true, department: 'Chemical Engineering', studentId: '210204003', level: 'Level 3', session: '2021-22'),
    GroupUser(id: '4', name: 'Nadia Rahman', avatar: '👩‍🎓', isOnline: true, department: 'Architecture', studentId: '190404004', level: 'Level 4', session: '2020-21'),
    GroupUser(id: '5', name: 'Karim Uddin', avatar: '👨‍💼', isOnline: false, department: 'Computer Science', studentId: '220204005', level: 'Level 2', session: '2022-23'),
    GroupUser(id: '6', name: 'Fatima Islam', avatar: '👩‍🔬', isOnline: true, department: 'Electrical Engineering', studentId: '230204006', level: 'Level 3', session: '2021-22'),
  ];

<<<<<<< HEAD
  List<String> get departments => ['All', ...allUsers.map((user) => user['department']).toSet()];
  List<String> get batches => ['All', ...allUsers.map((user) => user['batch']).toSet().toList()..sort()];
  List<String> get levels => ['All', 'Level 1', 'Level 2', 'Level 3', 'Level 4'];
=======
  List<GroupUser> filteredUsers = [];
>>>>>>> fb6ef7a3506d68d62b13e9d68a98d03b1277af89

  @override
  void initState() {
    super.initState();
    filteredUsers = allUsers;
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    List<GroupUser> filtered = allUsers.where((user) {
      bool matchesSearch = user.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          user.department.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          user.studentId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          user.level.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          user.session.toLowerCase().contains(_searchController.text.toLowerCase());
                          
      bool matchesDepartment = _selectedDepartment == 'all' || user.department == _selectedDepartment;
      bool matchesLevel = _selectedLevel == 'all' || user.level == _selectedLevel;
      bool matchesSession = _selectedSession == 'all' || user.session == _selectedSession;
      
      return matchesSearch && matchesDepartment && matchesLevel && matchesSession;
    }).toList();

    // Apply sorting
    switch (_selectedSortOption) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'department':
        filtered.sort((a, b) => a.department.compareTo(b.department));
        break;
      case 'level':
        filtered.sort((a, b) => a.level.compareTo(b.level));
        break;
      case 'session':
        filtered.sort((a, b) => a.session.compareTo(b.session));
        break;
    }

    setState(() {
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
    });
  }

  List<String> get uniqueDepartments {
    return ['all', ...allUsers.map((user) => user.department).toSet().toList()..sort()];
  }

  List<String> get uniqueLevels {
    return ['all', ...allUsers.map((user) => user.level).toSet().toList()..sort()];
  }

  List<String> get uniqueSessions {
    return ['all', ...allUsers.map((user) => user.session).toSet().toList()..sort()];
  }

  Widget _buildUserCard(GroupUser user) {
    final isSelected = _selectedUsers.any((u) => u.id == user.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
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
            Text('ID: ${user.studentId}'),
            Text(user.department),
            Text('${user.level} • ${user.session}'),
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
      body: Column(
        children: [
          // Group name input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
          ),
          
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search users...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          
          // Filter controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Sort filter only
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSortOption,
                        decoration: const InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'department', child: Text('Department')),
                          DropdownMenuItem(value: 'level', child: Text('Level')),
                          DropdownMenuItem(value: 'session', child: Text('Session')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedSortOption = value!);
                          _filterUsers();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Department and Level filters
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Dept',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          labelStyle: TextStyle(fontSize: 11),
                        ),
                        items: uniqueDepartments.map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(
                            dept == 'all' ? 'All' : dept,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDepartment = value!);
                          _filterUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: const InputDecoration(
                          labelText: 'Lvl',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          labelStyle: TextStyle(fontSize: 11),
                        ),
                        items: uniqueLevels.map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(
                            level == 'all' ? 'All' : level,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() => _selectedLevel = value!);
                          _filterUsers();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Session filter and Clear button
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedSession,
                        decoration: const InputDecoration(
                          labelText: 'Sess',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          labelStyle: TextStyle(fontSize: 11),
                        ),
                        items: uniqueSessions.map((session) => DropdownMenuItem(
                          value: session,
                          child: Text(
                            session == 'all' ? 'All' : session,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSession = value!);
                          _filterUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 2),
                    ElevatedButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
<<<<<<< HEAD
          // Members List
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      'No users found matching your criteria',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isSelected = selectedMembers.contains(user['name']);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.teal[100] : null,
                            child: Text(user['avatar']),
                          ),
                          title: Text(
                            user['name'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${user['studentId']}'),
                              Text('${user['department']} - ${user['level']}'),
                            ],
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedMembers.add(user['name']);
                                } else {
                                  selectedMembers.remove(user['name']);
                                }
                              });
                            },
                            activeColor: Colors.teal,
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
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
=======
          // Results summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${filteredUsers.length} users found • ${_selectedUsers.length} selected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
>>>>>>> fb6ef7a3506d68d62b13e9d68a98d03b1277af89
            ),
          ),
          
          // User list
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                return _buildUserCard(filteredUsers[index]);
              },
            ),
          ),
          
          // Selected users summary
          if (_selectedUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Users (${_selectedUsers.length}):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedUsers.map((user) => Chip(
                      label: Text(user.name),
                      onDeleted: () {
                        setState(() {
                          _selectedUsers.removeWhere((u) => u.id == user.id);
                        });
                      },
                    )).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedUsers.isNotEmpty && _groupNameController.text.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to group chat with selected users
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChatScreen(
                      groupName: _groupNameController.text,
                      memberCount: _selectedUsers.length + 1, // +1 for current user
                      avatar: '👥', // Default group avatar
                      courseFolder: 'General', // Default folder
                    ),
                    settings: const RouteSettings(name: '/group_chat'),
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Create Group'),
            )
          : null,
    );
  }
}
