import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart'; // adjust the path if needed

import '../../widgets/common_app_bar.dart';
import '../landing_page.dart';
import '../messages_page.dart';

const String baseUrl = 'http://10.103.135.42:5000'; // your Flask backend
class FindDonorsPage extends StatefulWidget {
  const FindDonorsPage({super.key});

  @override
  State<FindDonorsPage> createState() => _FindDonorsPageState();
}

class _FindDonorsPageState extends State<FindDonorsPage> {
  List<dynamic> donors = [];
  bool isLoading = true;
  String? selectedBloodGroup;
  String? errorMessage;

  final List<String> bloodGroups = [
    'AB+',
    'AB-',
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    fetchDonors();
  }

  Future<void> fetchDonors({String? bloodGroup}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          errorMessage = "Not authenticated. Please log in.";
        });
        // Redirect to login page after build complete
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
        return;
      }

      Uri url = Uri.parse('$baseUrl/donors');
      if (bloodGroup != null && bloodGroup.isNotEmpty) {
        url = Uri.parse('$baseUrl/donors')
            .replace(queryParameters: {'blood_group': bloodGroup});
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          donors = data;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Unauthorized. Please login again.';
        });
        await AuthService.logout();
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      } else {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        setState(() {
          errorMessage =
          'Failed to load donors: ${response.statusCode} ${body['msg'] ?? response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onBloodGroupSelected(String? group) {
    setState(() {
      selectedBloodGroup = group;
    });
    fetchDonors(bloodGroup: group);
  }

  Future<void> _callNumber(String contact) async {
    final uri = Uri.parse('tel:$contact');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch dialer')),
      );
    }
  }

  Future<void> _sendSMS(String contact) async {
    final uri = Uri.parse('sms:$contact');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch messaging app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('Find Blood Donors'),
        backgroundColor: Colors.red.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchDonors(bloodGroup: selectedBloodGroup),
          )
        ],
      ),
      body: Column(
        children: [
          // Blood group filter chips
          Container(
            color: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: bloodGroups.map((group) {
                  final isSelected = selectedBloodGroup == group;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(group),
                      selected: isSelected,
                      onSelected: (selected) {
                        onBloodGroupSelected(selected ? group : null);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.red.shade300,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
                : donors.isEmpty
                ? const Center(child: Text('No donors found'))
                : ListView.builder(
              itemCount: donors.length,
              itemBuilder: (context, index) {
                final donor = donors[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade400,
                    child: Text(
                      donor['blood_group'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    donor['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(donor['address'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.grey),
                        onPressed: () {
                          final contact = donor['contact'] ?? '';
                          if (contact.isNotEmpty) {
                            _callNumber(contact);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.message, color: Colors.grey),
                        onPressed: () {
                          final contact = donor['contact'] ?? '';
                          if (contact.isNotEmpty) {
                            _sendSMS(contact);
                          }
                        },
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
