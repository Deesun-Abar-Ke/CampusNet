import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'blood_bank/blood_bank_home_page.dart';
import 'blood_bank/request_blood_page.dart';
import 'blood_bank/find_donors_page.dart';
import 'blood_bank/register_donor_page.dart';
import 'blood_bank/all_blood_requests_page.dart';
import 'tuition_page.dart';
import 'chatbot_page.dart';
import 'messages_page.dart';
import 'profile_page.dart'; 

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String _currentPage = '/home';

  final Map<String, String> _titles = {
    '/home': '🏠 Home',
    '/blood-bank': '🩸 Blood Bank',
    '/blood-bank/request': '🙋 Request Blood',
    '/blood-bank/find': '🔍 Find Donors',
    '/blood-bank/register': '🩸 Register as Donor',
    '/blood-bank/all': '📄 All Blood Requests',
    '/tuition': '📚 Tuition',
    '/chatbot': '🤖 Chatbot',
    '/messages': '💬 Messages',
  };

  final Map<String, Color> _appBarColors = {
    '/home': const Color(0xFF003366),
    '/blood-bank': Colors.red,
    '/blood-bank/request': Colors.red,
    '/blood-bank/find': Colors.red,
    '/blood-bank/register': Colors.red,
    '/blood-bank/all': Colors.red,
    '/tuition': Colors.blue,
    '/chatbot': Colors.deepPurple,
    '/messages': Colors.teal,
  };

  void _handleNavigation(String route) {
    setState(() {
      _currentPage = route;
    });
    Navigator.pop(context);
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
                '👋 Hello, Student!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.grey),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Work in Progress")),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('profile.png'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        // Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureTile('Blood Bank', Icons.bloodtype, Colors.redAccent, '/blood-bank'),
                _buildFeatureTile('Blog', Icons.menu_book, Colors.orange, '/chatbot'),
                _buildFeatureTile('Tuition Media', Icons.school, Colors.green, '/tuition'),
                _buildFeatureTile('Messages', Icons.message, Colors.blueAccent, '/messages'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => _handleNavigation(route),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _getPage(String route) {
    switch (route) {
      case '/blood-bank':
        return const BloodBankHomePage();
      case '/blood-bank/request':
        return const RequestBloodPage();
      case '/blood-bank/find':
        return const FindDonorsPage();
      case '/blood-bank/register':
        return const RegisterDonorPage();
      case '/blood-bank/all':
        return const AllBloodRequestsPage();
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
        title: Text(_titles[_currentPage] ?? 'CampusNet'),
        backgroundColor: _appBarColors[_currentPage] ?? Colors.grey,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (_currentPage != '/home')
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _handleNavigation('/home'),
            ),
        ],
      ),
      drawer: AppDrawer(onNavigate: _handleNavigation),
      body: _getPage(_currentPage),
      floatingActionButton: _currentPage == '/home'
          ? FloatingActionButton.extended(
              onPressed: () => _handleNavigation('/chatbot'),
              backgroundColor: const Color.fromARGB(255, 161, 140, 197),
              label: const Text("Ask NetBot"),
              icon: const Icon(Icons.smart_toy),
            )
          : null,
    );
  }
}
