import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import '../landing_page.dart';
import '../messages_page.dart';

class FindDonorsPage extends StatelessWidget {
  const FindDonorsPage({super.key});

  final List<Map<String, String>> donors = const [
    {'name': 'Faria islam', 'location': 'Nodda', 'blood': 'B+', 'avatar': ''},
    {
      'name': 'Symum.Hasan',
      'location': 'Mirpur 10',
      'blood': 'O+',
      'avatar': '',
    },
    {
      'name': 'Fahima Sultana Orny',
      'location': 'Uttara',
      'blood': 'B+',
      'avatar': '',
    },
    {
      'name': 'Kafayet Mohammad Abdullah',
      'location': 'Motijheel',
      'blood': 'O+',
      'avatar': '',
    },
    {
      'name': 'A s hamim',
      'location': 'Dhaka cantonment',
      'blood': 'B+',
      'avatar': '',
    },
    {
      'name': 'HM Tamim',
      'location': 'Bashundhara R/A',
      'blood': 'B+',
      'avatar': '',
    },
    {
      'name': 'Mahdi Hasan Khan Chisty',
      'location': 'Nikunj2, Khilkhet',
      'blood': 'A+',
      'avatar': '',
    },
    {
      'name': 'Md.Abir Ahmed',
      'location': 'Dhaka,Bangladesh',
      'blood': 'AB+',
      'avatar': '',
    },
    {
      'name': 'Rafiqus Salam',
      'location': 'Bashundhara R/A',
      'blood': 'B+',
      'avatar': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('Find Blood Donors'),
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search donors...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Blood group filters
          Container(
            color: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final group in [
                    'AB+',
                    'AB-',
                    'A+',
                    'A-',
                    'B+',
                    'B-',
                    'O+',
                    'O-',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(group),
                        onSelected: (_) {},
                        backgroundColor: Colors.white,
                        selectedColor: Colors.red.shade300,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: donors.length,
              itemBuilder: (context, index) {
                final donor = donors[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade400,
                    child: Text(
                      donor['blood']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    donor['name']!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(donor['location']!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call, color: Colors.grey),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BloodBankMessagesWrapper(contactName: donor['name']!),
                            ),
                          );
                        },
                        child: const Icon(Icons.message, color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Wrapper for Messages Page to handle blood donor messaging
class BloodBankMessagesWrapper extends StatelessWidget {
  final String contactName;

  const BloodBankMessagesWrapper({super.key, required this.contactName});

  @override
  Widget build(BuildContext context) {
    // Get avatar for the contact (blood donor related)
    String getAvatarForContact(String name) {
      // Simple mapping for blood donors
      if (name.contains('Faria')) return '👩‍⚕️';
      if (name.contains('Ahmed')) return '👨‍⚕️';
      if (name.contains('Rahman')) return '🩸';
      if (name.contains('Khan')) return '👨‍🔬';
      return '🩸';
    }

    // Directly open ChatScreen for blood bank contact
    return ChatScreen(
      contactName: contactName,
      avatar: getAvatarForContact(contactName),
      isOnline: true,
      initialMessage: 'Hi! I saw your blood donor profile and would like to get in touch regarding blood donation.',
    );
  }
}
