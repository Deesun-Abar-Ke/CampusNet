import 'package:flutter/material.dart';
import '../screens/blood_bank/AmbulancePage.dart';
import '../screens/blood_bank/find_donors_page.dart';
import '../screens/blood_bank/request_blood_page.dart';
import '../screens/blood_bank/register_donor_page.dart';
import '../screens/blood_bank/all_blood_requests_page.dart';

class AppDrawer extends StatelessWidget {
  final void Function(String route) onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey),
            child: Text('App Menu', style: TextStyle(color: Colors.white, fontSize: 22)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => onNavigate('/home'),
          ),
          ExpansionTile(
            leading: const Icon(Icons.bloodtype),
            title: GestureDetector(
              onTap: () => onNavigate('/blood-bank'),
              child: const Text('Emergency'),
            ),
            children: [
              ListTile(
                title: const Text('Ambulance'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AmbulancePage()),
                  );
                },
              ),
              ListTile(
                title: const Text('Request Blood'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RequestBloodPage()),
                  );
                },
              ),
              ListTile(
                title: const Text('Find Donors'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindDonorsPage()),
                  );
                },
              ),
              ListTile(
                title: const Text('Register as Donor'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterDonorPage()),
                  );
                },
              ),
              ListTile(
                title: const Text('All Blood Requests'), // ✅ New item
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllBloodRequestsPage()),
                  );
                },

              ),

            ],
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Study Materials'),
            onTap: () => onNavigate('/study-materials'),
          ),

          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Tuition'),
            onTap: () => onNavigate('/tuition'),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chatbot'),
            onTap: () => onNavigate('/chatbot'),
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () => onNavigate('/messages'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => Navigator.pop(context), // close drawer
          ),
        ],
      ),
    );
  }
}
