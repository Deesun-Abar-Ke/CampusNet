import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'blood_bank/blood_bank_home_page.dart';
import 'blood_bank/request_blood_page.dart';
import 'blood_bank/find_donors_page.dart';
import 'blood_bank/register_donor_page.dart';
import 'blood_bank/all_blood_requests_page.dart';
import 'blood_bank/AmbulancePage.dart';

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

  final Map<String, String> _titles = {
    '/home': '🏠 Home',
    '/blood-bank': 'Emergency',
    '/blood-bank/ambulance': 'Call Ambulance',
    '/blood-bank/request': '🙋 Request Blood',
    '/blood-bank/find': '🔍 Find Donors',
    '/blood-bank/register': '🩸 Register as Donor',
    '/blood-bank/all': '📄 All Blood Requests',
    '/study-materials': '📚 Study Materials',
    '/tuition': '📚 Tuition',
    '/chatbot': '🤖 Chatbot',
    '/messages': '💬 Messages',
  };

  final Map<String, Color> _appBarColors = {
    '/home': Color(0xFF003366), // Navy Blue
    '/blood-bank': Colors.red, // Blood Bank main
    '/blood-bank/ambulance': Colors.red,
    '/blood-bank/request': Colors.red,
    '/blood-bank/find': Colors.red,
    '/blood-bank/register': Colors.red,
    '/blood-bank/all': Colors.red,
    '/study-materials': Colors.teal,
    '/tuition': Colors.blue, // Tuition
    '/chatbot': Colors.deepPurple, // Chatbot
    '/messages': Colors.teal, // Messaging
  };

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LandingPage()),
      (route) => false,
    );
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
                      label: 'Study\nMaterials',
                      icon: Icons.book,
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

  Widget _getPage(String route) {
    switch (route) {
      case '/blood-bank':
        return const BloodBankHomePage();
      case '/blood-bank/ambulance':
        return const AmbulancePage();
      case '/blood-bank/request':
        return const RequestBloodPage();
      case '/blood-bank/find':
        return const FindDonorsPage();
      case '/blood-bank/register':
        return const RegisterDonorPage();
      case '/blood-bank/all':
        return const AllBloodRequestsPage();
      case '/study-materials':
        return const StudyMaterialsHome();
      case '/tuition':
        return const TuitionPage();
      case '/chatbot':
        return const ChatbotPage();
      case '/messages':
        return const MessagesPage();
      case '/home':
      default:
        return _buildDashboard();
    }
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
