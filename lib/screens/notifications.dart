import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: const Text('Notifications'), showBackButton: true),
      body: _buildNotificationsList(),
    );
  }

  Widget _buildNotificationsList() {
    // Example notifications data
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'New Event: Coding Hackathon',
        'subtitle': 'Join the Coding Club Hackathon on Aug 5th! Prizes to win.',
        'icon': Icons.event,
        'color': Colors.blueAccent,
        'time': '2h ago',
      },
      {
        'title': 'New Study Material Added',
        'subtitle': 'Physics - Quantum Mechanics notes uploaded.',
        'icon': Icons.book,
        'color': Colors.green,
        'time': '4h ago',
      },
      {
        'title': 'Robotics Club Meeting',
        'subtitle': 'Weekly meeting at 5pm in Room 204.',
        'icon': Icons.groups,
        'color': Colors.deepPurple,
        'time': '1d ago',
      },
      {
        'title': 'Blood Donation Camp',
        'subtitle': 'Participate in the campus blood donation drive.',
        'icon': Icons.bloodtype,
        'color': Colors.redAccent,
        'time': '2d ago',
      },
      {
        'title': 'New Material: Math Practice Set',
        'subtitle': 'Algebra practice set uploaded by Prof. Sharma.',
        'icon': Icons.upload_file,
        'color': Colors.orange,
        'time': '3d ago',
      },
    ];

    return Container(
      child: notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif['color'],
                      child: Icon(notif['icon'], color: Colors.white),
                    ),
                    title: Text(
                      notif['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(notif['subtitle']),
                    trailing: Text(
                      notif['time'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
