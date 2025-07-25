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
    '/home': '🏠 Home',
    '/blood-bank': '🩸 Blood Bank',
    '/blood-bank/ambulance': 'Call Ambulance',
    '/blood-bank/request' : '🙋 Request Blood',
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
        return const Center(
          child: Text(
            "Welcome to Campus Net",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  void _handleNavigation(String route) {
    setState(() {
      _currentPage = route;
    });
    Navigator.pop(context); // Close drawer after selection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentPage] ?? 'App'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out")),
              );
            },
          )
        ],
      ),
      drawer: AppDrawer(onNavigate: _handleNavigation),
      body: _getPage(_currentPage),
    );
  }
}
