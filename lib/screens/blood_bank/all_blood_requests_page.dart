import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart'; // adjust path if necessary

import '../../widgets/common_app_bar.dart';
import '../landing_page.dart';
import '../messages_page.dart';

const String baseUrl = 'http://192.168.0.103:5000'; // your Flask backend
class AllBloodRequestsPage extends StatefulWidget {
  const AllBloodRequestsPage({super.key});

  @override
  State<AllBloodRequestsPage> createState() => _AllBloodRequestsPageState();
}

class _AllBloodRequestsPageState extends State<AllBloodRequestsPage> {
  List<dynamic> bloodRequests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
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
        // optional: redirect to login after a short delay
        Future.microtask(() =>
            Navigator.pushReplacementNamed(context, '/login'));
        return;
      }

      final url = Uri.parse('$baseUrl/blood_requests');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          bloodRequests = data;
        });
      } else if (res.statusCode == 401) {
        setState(() {
          errorMessage = 'Unauthorized. Please login again.';
        });
        await AuthService.logout();
        Future.microtask(() =>
            Navigator.pushReplacementNamed(context, '/login'));
      } else {
        final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        setState(() {
          errorMessage =
          'Failed to load requests: ${res.statusCode} ${body['msg'] ?? res.reasonPhrase}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('All Blood Requests'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchRequests,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : bloodRequests.isEmpty
          ? const Center(child: Text('No requests found'))
          : ListView.builder(
        itemCount: bloodRequests.length,
        itemBuilder: (context, index) {
          final request = bloodRequests[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
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
                          request['blood_group'] ?? '',
                          style: const TextStyle(
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${request['amount']} Bag (${request['blood_group']}) Blood Needed',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Location: ${request['location'] ?? ''}'),
                  const SizedBox(height: 4),
                  Text('Needed at: ${request['needed_at'] ?? ''}'),
                  if (request['note'] != null &&
                      request['note'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      request['note'],
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.call),
                        label: Text(request['contact'] ?? ''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.pink.shade400,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final contact =
                              request['contact'] ?? '';
                          if (contact.isNotEmpty) {
                            _callNumber(contact);
                          }
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
