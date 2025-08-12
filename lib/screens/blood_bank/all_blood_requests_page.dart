import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import '../messages_page.dart';

class AllBloodRequestsPage extends StatelessWidget {
  const AllBloodRequestsPage({super.key});

  final List<Map<String, String>> bloodRequests = const [
    {
      'blood': 'B+',
      'bags': '1',
      'name': 'Mukramur Rahman',
      'location': 'Birdem Hospital',
      'time': 'Jun 17 at 7:36 AM',
      'neededTime': 'Jun 18 at 12:00 PM',
      'reason': 'surgery patient',
      'phone': '01621900722',
    },
    {
      'blood': 'O-',
      'bags': '2',
      'name': 'al sabab',
      'location': 'Birdem Hospital',
      'time': 'Jun 15 at 3:54 AM',
      'neededTime': 'Jun 16 at 12:00 PM',
      'reason': '',
      'phone': '01954567008',
    },
    {
      'blood': 'A-',
      'bags': '1',
      'name': 'Israk Iram Oyshe',
      'location': 'Mirpur',
      'time': 'Apr 18 at 4:55 AM',
      'neededTime': 'Apr 19 at 10:00 AM',
      'reason': 'Required for a 2 day old baby',
      'phone': '01552335202',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('All Blood Requests'),
        showBackButton: true,
      ),
      body: ListView.builder(
        itemCount: bloodRequests.length,
        itemBuilder: (context, index) {
          final request = bloodRequests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Text(
                          request['blood']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${request['bags']} Bag (${request['blood']}) Blood Needed',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('By ${request['name']}, ${request['time']}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(request['location']!),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text('Needed on ${request['neededTime']}'),
                    ],
                  ),
                  if (request['reason']!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      request['reason']!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('CHAT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BloodRequestMessagesWrapper(contactName: request['name']!),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.call),
                        label: Text(request['phone']!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade400,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Implement call function or use url_launcher
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Wrapper for Messages Page to handle blood request messaging
class BloodRequestMessagesWrapper extends StatelessWidget {
  final String contactName;

  const BloodRequestMessagesWrapper({super.key, required this.contactName});

  @override
  Widget build(BuildContext context) {
    // Get avatar for the contact (blood request related)
    String getAvatarForContact(String name) {
      // Simple mapping for blood requesters
      if (name.contains('Ahmed')) return '🆘';
      if (name.contains('Rahman')) return '🩸';
      if (name.contains('Khan')) return '🏥';
      if (name.contains('Begum')) return '👩‍⚕️';
      return '🆘';
    }

    // Directly open ChatScreen for blood request contact
    return ChatScreen(
      contactName: contactName,
      avatar: getAvatarForContact(contactName),
      isOnline: true,
      initialMessage: 'Hi! I saw your blood request and would like to help. Please let me know the details.',
    );
  }
}
