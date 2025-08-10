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
import 'study_materials/study_materials_home.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String _currentPage = '/home';

  final Map<String, String> _titles = {
    '/home': 'Campus Feed',
    '/blood-bank': 'Emergency',
    '/blood-bank/ambulance': 'Call Ambulance',
    '/blood-bank/request': ' Request Blood',
    '/blood-bank/find': ' Find Donors',
    '/blood-bank/register': ' Register as Donor',
    '/blood-bank/all': 'All Blood Requests',
    '/study-materials': ' Study Materials',
    '/tuition': ' Tuition',
    '/chatbot': ' Chatbot',
    '/messages': ' Messages',
  };

  final Map<String, Color> _appBarColors = {
    '/home': const Color(0xFF003366),
    '/blood-bank': Colors.red,
    '/blood-bank/ambulance': Colors.red,
    '/blood-bank/request': Colors.red,
    '/blood-bank/find': Colors.red,
    '/blood-bank/register': Colors.red,
    '/blood-bank/all': Colors.red,
    '/study-materials': Colors.teal,
    '/tuition': Colors.blue,
    '/chatbot': Colors.deepPurple,
    '/messages': Colors.teal,
  };

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
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Banner widget added here
            const _LandingBanner(),
            const SizedBox(height: 20),
            const BlogPostCard(
              clubName: 'Programming Club',
              timeAgo: '2 hours ago',
              content:
              '🚀 Join us for the upcoming Hackathon! Great prizes to be won. Register now to showcase your coding skills and innovation.',
              icon: Icons.computer,
              color: Colors.indigo,
            ),
            const BlogPostCard(
              clubName: 'Photography Club',
              timeAgo: '5 hours ago',
              content:
              '📸 Photography exhibition this weekend! Come see the amazing captures by our talented members.',
              icon: Icons.camera_alt,
              color: Colors.purple,
            ),
            const BlogPostCard(
              clubName: 'Drama Club',
              timeAgo: '1 day ago',
              content:
              '🎭 Auditions open for the annual stage show! Don’t miss the spotlight.',
              icon: Icons.theater_comedy,
              color: Colors.deepOrange,
            ),
          ],
        );
    }
  }

  void _handleNavigation(String route) {
    setState(() {
      _currentPage = route;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentPage] ?? 'App'),
        centerTitle: true,
        backgroundColor: _appBarColors[_currentPage] ?? Colors.grey,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          )

        ],
      ),
      drawer: AppDrawer(onNavigate: _handleNavigation),
      body: _getPage(_currentPage),
    );
  }
}

class _LandingBanner extends StatelessWidget {
  const _LandingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      // No padding inside container
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16), // left spacing
          const Icon(
            Icons.school,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 16), // top spacing
                Text(
                  'Welcome to CampusNet!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your ultimate solution for campus emergencies, learning, and connectivity.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 16), // bottom spacing
              ],
            ),
          ),
          const SizedBox(width: 16), // right spacing
        ],
      ),
    );
  }
}

class BlogPostCard extends StatelessWidget {
  final String clubName;
  final String timeAgo;
  final String content;
  final IconData icon;
  final Color color;

  const BlogPostCard({
    super.key,
    required this.clubName,
    required this.timeAgo,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  clubName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                SizedBox(width: 16),
                Icon(Icons.comment_outlined, size: 20, color: Colors.grey),
                SizedBox(width: 16),
                Icon(Icons.share_outlined, size: 20, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }
}
