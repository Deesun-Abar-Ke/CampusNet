import 'package:flutter/material.dart';
import 'blood_bank/blood_bank_home_page.dart';
import 'tuition_page.dart';
import 'chatbot_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'study_materials/study_materials_home.dart';
import 'notifications.dart';
import '_feature_icon.dart';
import '_club_post_card.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Sample club posts data
  final List<Map<String, dynamic>> _clubPosts = [
    {
      'clubName': 'Programming Club',
      'timeAgo': '2 hours ago',
      'content':
          'Join us for the upcoming Hackathon! Great prizes to be won. Register now to showcase your coding skills and innovation.',
      'avatarUrl': 'assets/computer_club.jpeg',
    },
    {
      'clubName': 'Photography Club',
      'timeAgo': '5 hours ago',
      'content':
          'Photography exhibition this weekend! Come see the amazing captures by our talented members.',
      'imageUrl': 'assets/exhibition.jpeg',
      'avatarUrl': 'assets/photography_club.png',
    },
    {
      'clubName': 'Debating Club',
      'timeAgo': '1 day ago',
      'content':
          'Inter-university debate competition registration is now open. Form your team of three and register before July 30th.',
      'avatarUrl': 'assets/debate_club.png',
    },
  ];

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // Top greeting & profile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                ' Welcome! ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('profile.png'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Feature Icons Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MIST CampusNet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    FeatureIcon(
                      label: 'Resource\nBank',
                      icon: Icons.library_books,
                      color: Colors.blue,
                      onTap: () => _navigateToPage(const StudyMaterialsHome()),
                    ),
                    const SizedBox(width: 24),
                    FeatureIcon(
                      label: 'Messages',
                      icon: Icons.message,
                      color: Colors.green,
                      onTap: () => _navigateToPage(const MessagesPage()),
                    ),
                    const SizedBox(width: 24),
                    FeatureIcon(
                      label: 'Emergency',
                      icon: Icons.emergency,
                      color: Colors.red,
                      onTap: () => _navigateToPage(const BloodBankHomePage()),
                    ),
                    const SizedBox(width: 24),
                    FeatureIcon(
                      label: 'Tuition\nMedia',
                      icon: Icons.school,
                      color: Colors.orange,
                      onTap: () => _navigateToPage(const TuitionPage()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Club Posts Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Blog Posts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _clubPosts.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final post = _clubPosts[index];
                    return ClubPostCard(
                      clubName: post['clubName'],
                      timeAgo: post['timeAgo'],
                      content: post['content'],
                      imageUrl: post['imageUrl'],
                      avatarUrl: post['avatarUrl'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusNet'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _buildDashboard(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToPage(const ChatbotPage()),
        backgroundColor: const Color.fromARGB(255, 161, 140, 197),
        label: const Text("Ask NetBot"),
        icon: const Icon(Icons.smart_toy),
      ),
    );
  }
}
