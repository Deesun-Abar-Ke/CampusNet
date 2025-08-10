import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AmbulancePage extends StatefulWidget {
  const AmbulancePage({super.key});

  @override
  State<AmbulancePage> createState() => _AmbulancePageState();
}

class _AmbulancePageState extends State<AmbulancePage> {
  final List<Map<String, String>> allAmbulances = [
    {
      'provider': 'Apollo Hospital',
      'phone': '01700000001',
      'location': 'Bashundhara, Dhaka',
      'type': 'AC',
      'availability': 'Available',
    },
    {
      'provider': 'Square Hospital',
      'phone': '01700000002',
      'location': 'Panthapath, Dhaka',
      'type': 'ICU',
      'availability': 'Busy',
    },
    {
      'provider': 'Popular Diagnostic',
      'phone': '01700000003',
      'location': 'Dhanmondi, Dhaka',
      'type': 'Non-AC',
      'availability': 'Available',
    },
    {
      'provider': 'United Hospital',
      'phone': '01700000004',
      'location': 'Gulshan, Dhaka',
      'type': 'AC',
      'availability': 'Available',
    },
  ];

  String selectedType = 'All';
  String selectedAvailability = 'All';
  String searchQuery = '';

  List<Map<String, String>> get filteredAmbulances {
    return allAmbulances.where((amb) {
      final matchType =
          selectedType == 'All' || amb['type'] == selectedType;
      final matchAvail =
          selectedAvailability == 'All' || amb['availability'] == selectedAvailability;
      final matchSearch = amb['provider']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          amb['location']!.toLowerCase().contains(searchQuery.toLowerCase());
      return matchType && matchAvail && matchSearch;
    }).toList();
  }

  void _callAmbulance(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Services'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by provider or area',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  onChanged: (val) => setState(() => selectedType = val!),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Types')),
                    DropdownMenuItem(value: 'AC', child: Text('AC')),
                    DropdownMenuItem(value: 'ICU', child: Text('ICU')),
                    DropdownMenuItem(value: 'Non-AC', child: Text('Non-AC')),
                  ],
                ),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: selectedAvailability,
                  onChanged: (val) => setState(() => selectedAvailability = val!),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status')),
                    DropdownMenuItem(value: 'Available', child: Text('Available')),
                    DropdownMenuItem(value: 'Busy', child: Text('Busy')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredAmbulances.length,
              itemBuilder: (context, index) {
                final amb = filteredAmbulances[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.local_hospital, color: Colors.red),
                    title: Text(
                      amb['provider']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${amb['location']} • ${amb['type']}'),
                        Text('Status: ${amb['availability']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () => _callAmbulance(amb['phone']!),
                        ),
                      ],
                    ),
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
