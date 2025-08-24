import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../messages/messages_page.dart';
import '../messages/chat_screen.dart';
import '../landing_page.dart';
import 'create_tuition_post_page.dart';

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
        body: const TabBarView(children: [TutorsList(), RequestsList()]),
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
  const TutorsList({super.key});

  @override
  State<TutorsList> createState() => _TutorsListState();
}

class _TutorsListState extends State<TutorsList> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchTutions();
  }

  Future<List<dynamic>> fetchTutions() async {
    final url = Uri.parse('$baseUrl/tutions');
    final res = await http.get(url);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Failed to load tutions');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        // Tutors list: show posts where req_type != 'request' (providers/offers)
        final tutors = items.where((e) => (e['req_type'] ?? '').toString().toLowerCase() != 'request').toList();

        if (tutors.isEmpty) {
          return const Center(child: Text('No tutors found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tutors.length,
          itemBuilder: (context, i) {
            final t = tutors[i];
            return TutionCard(
              title: (t['subject'] ?? t['post_id'] ?? 'Tuition').toString(),
              classLevel: (t['class'] ?? t['class_level'] ?? '').toString(),
              location: (t['location'] ?? '').toString(),
              remuneration: (t['remuneration'] ?? t['renumeration'] ?? '').toString(),
              description: (t['description'] ?? '').toString(),
            );
          },
        );
      },
    );
  }
}

class RequestsList extends StatefulWidget {
  const RequestsList({super.key});

  @override
  State<RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<RequestsList> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchTutions();
  }

  Future<List<dynamic>> fetchTutions() async {
    final url = Uri.parse('$baseUrl/tutions');
    final res = await http.get(url);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Failed to load tutions');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        // Requests list: show posts where req_type == 'request'
        final requests = items.where((e) => (e['req_type'] ?? '').toString().toLowerCase() == 'request').toList();

        if (requests.isEmpty) {
          return const Center(child: Text('No requests found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, i) {
            final t = requests[i];
            return TutionCard(
              title: (t['subject'] ?? t['post_id'] ?? 'Tuition Request').toString(),
              classLevel: (t['class'] ?? t['class_level'] ?? '').toString(),
              location: (t['location'] ?? '').toString(),
              remuneration: (t['remuneration'] ?? t['renumeration'] ?? '').toString(),
              description: (t['description'] ?? '').toString(),
            );
          },
        );
      },
    );
  }
}

class TutorCard extends StatelessWidget {
  final String name;
  final String subject;
  final String classLevel;
  final String location;
  final String remuneration;
  final String description;

  const TutorCard({
    super.key,
    required this.name,
    required this.subject,
    required this.classLevel,
    required this.location,
    required this.remuneration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFDECEC),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile icon, name, and message icon
            Row(
              children: [
                // Profile Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: Colors.blue[800], size: 24),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Message Icon
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.message,
                      color: Colors.teal[700],
                      size: 20,
                    ),
                    onPressed: () {
                      // Directly navigate to messages page with the contact
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagesPageWrapper(contactName: name),
                        ),
                      );
                    },
                    tooltip: 'Send Message',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject
            _buildInfoRow(
              icon: Icons.book,
              label: 'Subject',
              value: subject,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),

            // Class
            _buildInfoRow(
              icon: Icons.grade,
              label: 'Class',
              value: classLevel,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),

            // Location
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: location,
              color: Colors.red,
            ),
            const SizedBox(height: 8),

            // Remuneration
            _buildInfoRow(
              icon: Icons.attach_money,
              label: 'Remuneration',
              value: remuneration,
              color: Colors.green,
            ),
            const SizedBox(height: 12),

            // Description
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


class TutionCard extends StatelessWidget {
  final String title;
  final String classLevel;
  final String location;
  final String remuneration;
  final String description;

  const TutionCard({
    super.key,
    required this.title,
    required this.classLevel,
    required this.location,
    required this.remuneration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFDECEC),
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
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: Colors.blue[800], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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