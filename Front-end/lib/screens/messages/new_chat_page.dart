import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'messages_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
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
    return Scaffold(
      appBar: const CommonAppBar(
        title: Text('Start New Chat'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, student ID, or phone...',
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
                const SizedBox(height: 16),
                
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
          
          // Results
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
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
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
                          title: Text(
                            user['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${user['studentId']}'),
                              Text('${user['department']} - ${user['level']}'),
                              Text('Batch: ${user['batch']}'),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              // Navigate to chat screen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    contactName: user['name'],
                                    avatar: user['avatar'],
                                    isOnline: user['isOnline'],
                                    initialMessage: 'Hi! I found you through the campus network.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Chat'),
                          ),
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
}
