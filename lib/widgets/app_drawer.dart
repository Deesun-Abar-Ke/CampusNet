import 'package:flutter/material.dart';

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
              child: const Text('Blood Bank'),
            ),
            children: [
              ListTile(
                title: const Text('Request Blood'),
                onTap: () => onNavigate('/blood-bank/request'),
              ),
              ListTile(
                title: const Text('Find Donors'),
                onTap: () => onNavigate('/blood-bank/find'),
              ),
              ListTile(
                title: const Text('Register as Donor'),
                onTap: () => onNavigate('/blood-bank/register'),
              ),
            ],
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
