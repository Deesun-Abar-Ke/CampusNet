import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '_edit_profile_sheet.dart';
import '../widgets/common_app_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: CommonAppBar(title: "My Profile", showBackButton: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Banner + Profile
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.indigo,
                ),
                Positioned(
                  top: 40,
                  left: MediaQuery.of(context).size.width / 2 - 50,
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('profile.png'),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name and Role
            const Text(
              "Fahim Tazwar Deesun",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Undergraduate Student, CSE",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Personal Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: const [
                      _InfoRow(
                        icon: Icons.email,
                        label: "Email",
                        value: "fahim.deesun@mist.ac.bd",
                      ),
                      Divider(),
                      _InfoRow(
                        icon: Icons.badge,
                        label: "Student ID",
                        value: "190204000X",
                      ),
                      Divider(),
                      _InfoRow(
                        icon: Icons.school,
                        label: "Department",
                        value: "Computer Science & Engineering",
                      ),
                      Divider(),
                      _InfoRow(
                        icon: Icons.apartment,
                        label: "University",
                        value: "Military Institute of Science & Technology",
                      ),
                      Divider(),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: "Batch",
                        value: "2020",
                      ),
                      Divider(),
                      _InfoRow(
                        icon: Icons.cake,
                        label: "Date of Birth",
                        value: "15 July 2002",
                      ),
                      Divider(),
                      _InfoRow(
                        icon: Icons.phone_android,
                        label: "Phone",
                        value: "+8801XXXXXXXXX",
                      ),
                      Divider(),
                      _InfoRow(
                        icon: Icons.location_city,
                        label: "Hometown",
                        value: "Dhaka, Bangladesh",
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Social Media Links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          final Uri url = Uri.parse(
                            'https://www.linkedin.com/in/fahim-tazwar-deesun-6b389b247/',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: const _InfoRow(
                          icon: Icons.link,
                          label: "LinkedIn",
                          value: "View Profile →",
                        ),
                      ),
                      const Divider(),
                      InkWell(
                        onTap: () async {
                          final Uri url = Uri.parse(
                            'https://www.facebook.com/fahim.tazwar.deesun/',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: const _InfoRow(
                          icon: Icons.facebook,
                          label: "Facebook",
                          value: "View Profile →",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 196, 199, 221),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (context) => const EditProfileSheet(),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Profile"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for info rows
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: label == "LinkedIn" || label == "Facebook"
                  ? Colors.blue.shade700
                  : Colors.black87,
              decoration: label == "LinkedIn" || label == "Facebook"
                  ? TextDecoration.underline
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
