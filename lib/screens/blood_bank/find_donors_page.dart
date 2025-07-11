import 'package:flutter/material.dart';

class FindDonorsPage extends StatelessWidget {
  const FindDonorsPage({super.key});

  final List<Map<String, String>> donors = const [
    {
      'name': 'Faria islam',
      'location': 'Nodda',
      'blood': 'B+',
      'avatar': '',
    },
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
      appBar: AppBar(
        title: const Text('Find Blood Donors'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.search),
          )
        ],
      ),
      body: Column(
        children: [
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
                    'O-'
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
                    children: const [
                      Icon(Icons.call, color: Colors.grey),
                      SizedBox(width: 16),
                      Icon(Icons.message, color: Colors.grey),
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
