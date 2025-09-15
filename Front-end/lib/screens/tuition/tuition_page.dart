import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../messages/messages_page.dart';
import '../messages/chat_screen.dart';
import '../home/landing_page.dart';
import 'create_tuition_post_page.dart';

enum CardType { tutor, request }

class TuitionPage extends StatelessWidget {
  const TuitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          title: const Text('Tuition'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (route) => false,
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'TUTORS'),
              Tab(text: 'REQUESTS'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          TutorsList(cardType: CardType.tutor),
          RequestsList(cardType: CardType.request),
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTuitionPostPage()),
            );
          },
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class TutorsList extends StatefulWidget {
  final CardType cardType;
  
  const TutorsList({super.key, required this.cardType});

  @override
  State<TutorsList> createState() => _TutorsListState();
}

class _TutorsListState extends State<TutorsList> {
  late Future<List<dynamic>> _future;
  List<dynamic> _allTutors = [];
  List<dynamic> _filteredTutors = [];
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubjectFilter = 'All';
  String _selectedClassFilter = 'All';
  String _selectedLocationFilter = 'All';

  @override
  void initState() {
    super.initState();
    _future = fetchTutions();
    _searchController.addListener(_filterTutors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchTutions() async {
    final url = Uri.parse('${Config.baseUrl}/tutions');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final items = jsonDecode(res.body) as List<dynamic>;
      final tutors = items.where((e) => (e['req_type'] ?? '').toString().toLowerCase() != 'request').toList();
      _allTutors = tutors;
      _filteredTutors = tutors;
      return tutors;
    }
    throw Exception('Failed to load tutions');
  }

  void _filterTutors() {
    setState(() {
      _filteredTutors = _allTutors.where((tutor) {
        final userName = (tutor['user_name'] ?? '').toString().toLowerCase();
        final subject = (tutor['subject'] ?? '').toString().toLowerCase();
        final classLevel = (tutor['class'] ?? '').toString().toLowerCase();
        final location = (tutor['location'] ?? '').toString().toLowerCase();
        final searchQuery = _searchController.text.toLowerCase();

        // Text search
        bool matchesSearch = searchQuery.isEmpty ||
            userName.contains(searchQuery) ||
            subject.contains(searchQuery) ||
            classLevel.contains(searchQuery) ||
            location.contains(searchQuery);

        // Filter by subject
        bool matchesSubject = _selectedSubjectFilter == 'All' ||
            subject.contains(_selectedSubjectFilter.toLowerCase());

        // Filter by class
        bool matchesClass = _selectedClassFilter == 'All' ||
            classLevel.contains(_selectedClassFilter.toLowerCase());

        // Filter by location
        bool matchesLocation = _selectedLocationFilter == 'All' ||
            location.contains(_selectedLocationFilter.toLowerCase());

        return matchesSearch && matchesSubject && matchesClass && matchesLocation;
      }).toList();
    });
  }

  Set<String> _getUniqueValues(String field) {
    return _allTutors.map((e) => (e[field] ?? '').toString()).where((s) => s.isNotEmpty).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showSearch = false),
      child: Column(
        children: [
          // Search section - always visible search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
            ),
            child: Column(
              children: [
                // Search bar - always visible
                GestureDetector(
                  onTap: () => setState(() => _showSearch = true),
                  child: TextField(
                    controller: _searchController,
                    onTap: () => setState(() => _showSearch = true),
                    decoration: InputDecoration(
                      hintText: 'Search by name, subject, class, or location...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                // Filter chips - only show when search is focused
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showSearch ? 60 : 0,
                  child: _showSearch ? Column(
                    children: [
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Subject', _selectedSubjectFilter, _getUniqueValues('subject')),
                            const SizedBox(width: 8),
                            _buildFilterChip('Class', _selectedClassFilter, _getUniqueValues('class')),
                            const SizedBox(width: 8),
                            _buildFilterChip('Location', _selectedLocationFilter, _getUniqueValues('location')),
                          ],
                        ),
                      ),
                    ],
                  ) : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (_filteredTutors.isEmpty) {
                  return const Center(child: Text('No tutors found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredTutors.length,
                  itemBuilder: (context, i) {
                    final t = _filteredTutors[i];
                    return TutionCard(
                      cardType: widget.cardType,
                      userName: (t['user_name'] ?? '').toString(),
                      title: (t['subject'] ?? t['post_id'] ?? 'Tuition').toString(),
                      classLevel: (t['class'] ?? t['class_level'] ?? '').toString(),
                      location: (t['location'] ?? '').toString(),
                      remuneration: (t['remuneration'] ?? t['renumeration'] ?? '').toString(),
                      description: (t['description'] ?? '').toString(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String currentValue, Set<String> options) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text('$label: $currentValue'),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.blue[300]!),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'All', child: Text('All')),
        ...options.map((option) => PopupMenuItem(value: option, child: Text(option))),
      ],
      onSelected: (value) {
        setState(() {
          if (label == 'Subject') _selectedSubjectFilter = value;
          else if (label == 'Class') _selectedClassFilter = value;
          else if (label == 'Location') _selectedLocationFilter = value;
          _filterTutors();
        });
      },
    );
  }
}

class RequestsList extends StatefulWidget {
  final CardType cardType;
  
  const RequestsList({super.key, required this.cardType});

  @override
  State<RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<RequestsList> {
  late Future<List<dynamic>> _future;
  List<dynamic> _allRequests = [];
  List<dynamic> _filteredRequests = [];
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubjectFilter = 'All';
  String _selectedClassFilter = 'All';
  String _selectedLocationFilter = 'All';

  @override
  void initState() {
    super.initState();
    _future = fetchTutions();
    _searchController.addListener(_filterRequests);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchTutions() async {
    final url = Uri.parse('${Config.baseUrl}/tutions');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final items = jsonDecode(res.body) as List<dynamic>;
      final requests = items.where((e) => (e['req_type'] ?? '').toString().toLowerCase() == 'request').toList();
      _allRequests = requests;
      _filteredRequests = requests;
      return requests;
    }
    throw Exception('Failed to load tutions');
  }

  void _filterRequests() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        final userName = (request['user_name'] ?? '').toString().toLowerCase();
        final subject = (request['subject'] ?? '').toString().toLowerCase();
        final classLevel = (request['class'] ?? '').toString().toLowerCase();
        final location = (request['location'] ?? '').toString().toLowerCase();
        final searchQuery = _searchController.text.toLowerCase();

        // Text search
        bool matchesSearch = searchQuery.isEmpty ||
            userName.contains(searchQuery) ||
            subject.contains(searchQuery) ||
            classLevel.contains(searchQuery) ||
            location.contains(searchQuery);

        // Filter by subject
        bool matchesSubject = _selectedSubjectFilter == 'All' ||
            subject.contains(_selectedSubjectFilter.toLowerCase());

        // Filter by class
        bool matchesClass = _selectedClassFilter == 'All' ||
            classLevel.contains(_selectedClassFilter.toLowerCase());

        // Filter by location
        bool matchesLocation = _selectedLocationFilter == 'All' ||
            location.contains(_selectedLocationFilter.toLowerCase());

        return matchesSearch && matchesSubject && matchesClass && matchesLocation;
      }).toList();
    });
  }

  Set<String> _getUniqueValues(String field) {
    return _allRequests.map((e) => (e[field] ?? '').toString()).where((s) => s.isNotEmpty).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showSearch = false),
      child: Column(
        children: [
          // Search section - always visible search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
            ),
            child: Column(
              children: [
                // Search bar - always visible
                GestureDetector(
                  onTap: () => setState(() => _showSearch = true),
                  child: TextField(
                    controller: _searchController,
                    onTap: () => setState(() => _showSearch = true),
                    decoration: InputDecoration(
                      hintText: 'Search by name, subject, class, or location...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                // Filter chips - only show when search is focused
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showSearch ? 60 : 0,
                  child: _showSearch ? Column(
                    children: [
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Subject', _selectedSubjectFilter, _getUniqueValues('subject')),
                            const SizedBox(width: 8),
                            _buildFilterChip('Class', _selectedClassFilter, _getUniqueValues('class')),
                            const SizedBox(width: 8),
                            _buildFilterChip('Location', _selectedLocationFilter, _getUniqueValues('location')),
                          ],
                        ),
                      ),
                    ],
                  ) : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (_filteredRequests.isEmpty) {
                  return const Center(child: Text('No requests found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, i) {
                    final t = _filteredRequests[i];
                    return TutionCard(
                      cardType: widget.cardType,
                      userName: (t['user_name'] ?? '').toString(),
                      title: (t['subject'] ?? t['post_id'] ?? 'Tuition Request').toString(),
                      classLevel: (t['class'] ?? t['class_level'] ?? '').toString(),
                      location: (t['location'] ?? '').toString(),
                      remuneration: (t['remuneration'] ?? t['renumeration'] ?? '').toString(),
                      description: (t['description'] ?? '').toString(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String currentValue, Set<String> options) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text('$label: $currentValue'),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.orange[300]!),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'All', child: Text('All')),
        ...options.map((option) => PopupMenuItem(value: option, child: Text(option))),
      ],
      onSelected: (value) {
        setState(() {
          if (label == 'Subject') _selectedSubjectFilter = value;
          else if (label == 'Class') _selectedClassFilter = value;
          else if (label == 'Location') _selectedLocationFilter = value;
          _filterRequests();
        });
      },
    );
  }
}

class TutionCard extends StatelessWidget {
  final CardType cardType;
  final String userName;
  final String title;
  final String classLevel;
  final String location;
  final String remuneration;
  final String description;

  const TutionCard({
    super.key,
    required this.cardType,
    required this.userName,
    required this.title,
    required this.classLevel,
    required this.location,
    required this.remuneration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // Different colors for tutors vs requests
    Color cardColor;
    Color iconBgColor;
    Color iconColor;
    Color messageBgColor;
    Color messageIconColor;
    
    if (cardType == CardType.tutor) {
      cardColor = const Color(0xFFE8F5E8); // Light green
      iconBgColor = Colors.blue[100]!;
      iconColor = Colors.blue[800]!;
      messageBgColor = Colors.teal[100]!;
      messageIconColor = Colors.teal[700]!;
    } else {
      cardColor = const Color(0xFFFFF3E0); // Light orange
      iconBgColor = Colors.orange[100]!;
      iconColor = Colors.orange[800]!;
      messageBgColor = Colors.deepOrange[100]!;
      messageIconColor = Colors.deepOrange[700]!;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userName.isNotEmpty ? userName : 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Message Icon
                Container(
                  decoration: BoxDecoration(
                    color: messageBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.message,
                      color: messageIconColor,
                      size: 20,
                    ),
                    onPressed: () {
                      // Navigate to chat with the poster's name
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagesPageWrapper(contactName: userName.isNotEmpty ? userName : 'User'),
                        ),
                      );
                    },
                    tooltip: 'Send Message',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.book,
              label: 'Subject',
              value: title,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.grade,
              label: 'Class',
              value: classLevel,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: location,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.attach_money,
              label: 'Remuneration',
              value: remuneration,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color[700]),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// Wrapper for Messages Page to handle contact-specific messaging
class MessagesPageWrapper extends StatelessWidget {
  final String contactName;

  const MessagesPageWrapper({super.key, required this.contactName});

  @override
  Widget build(BuildContext context) {
    // Get avatar for the contact (you can create a mapping function)
    String getAvatarForContact(String name) {
      // Simple mapping - you can make this more sophisticated
      if (name.contains('Rahman')) return '👨‍🏫';
      if (name.contains('Ahmed')) return '👨‍🔬';
      if (name.contains('Sarah')) return '👩‍💻';
      if (name.contains('Nadia')) return '👩‍🎓';
      return '👨‍🎓';
    }

    // Directly open ChatScreen instead of MessagesPage
    return ChatScreen(
      contactName: contactName,
      avatar: getAvatarForContact(contactName),
      isOnline: true,
      initialMessage: 'Hi! I saw your tutoring profile and I\'m interested in your services.',
    );
  }
}
