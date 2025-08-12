import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'messages_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
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

  List<String> get departments => ['All', ...allUsers.map((user) => user['department']).toSet().toList()];
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
    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('Create Group'),
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: selectedMembers.isNotEmpty && groupName.isNotEmpty
                ? () {
                    // Create group and navigate to it
                    _createGroup();
                  }
                : null,
            child: Text(
              'CREATE',
              style: TextStyle(
                color: selectedMembers.isNotEmpty && groupName.isNotEmpty
                    ? Colors.white
                    : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group Name Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Group Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter group name...',
                    prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      groupName = value;
                    });
                  },
                ),
                
                if (selectedMembers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Selected Members (${selectedMembers.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: selectedMembers.map((member) {
                      final user = allUsers.firstWhere((u) => u['name'] == member);
                      return Chip(
                        avatar: Text(user['avatar']),
                        label: Text(
                          member,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selectedMembers.remove(member);
                          });
                        },
                        backgroundColor: Colors.teal[100],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search members to add...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Department',
                        selectedDepartment,
                        departments,
                        (value) => setState(() => selectedDepartment = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        'Batch',
                        selectedBatch,
                        batches,
                        (value) => setState(() => selectedBatch = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        'Level',
                        selectedLevel,
                        levels,
                        (value) => setState(() => selectedLevel = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
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
                            child: Text(user['avatar']),
                            backgroundColor: isSelected ? Colors.teal[100] : null,
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
            ),
          ),
        ),
      ],
    );
  }

  void _createGroup() {
    if (groupName.isNotEmpty && selectedMembers.isNotEmpty) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "$groupName" created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigate to the newly created group chat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(
            groupName: groupName,
            memberCount: selectedMembers.length + 1, // +1 for current user
            avatar: '👥',
            courseFolder: 'General Discussion',
          ),
        ),
      );
    }
  }
}
