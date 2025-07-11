import 'package:flutter/material.dart';
import 'request_blood_page.dart';
import 'find_donors_page.dart';
import 'register_donor_page.dart';
import 'all_blood_requests_page.dart';

class BloodBankHomePage extends StatelessWidget {
  const BloodBankHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Soft, clean background



      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildTile(
              context,
              icon: Icons.search,
              label: 'Find Donors',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindDonorsPage()),
                );
              },
            ),
            _buildTile(
              context,
              icon: Icons.volunteer_activism,
              label: 'Request Blood',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RequestBloodPage()),
                );
              },
            ),
            _buildTile(
              context,
              icon: Icons.person_add,
              label: 'Be a Donor',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterDonorPage()),
                );
              },
            ),
            _buildTile(
              context,
              icon: Icons.list_alt,
              label: 'Blood Requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllBloodRequestsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return Material(
      color: const Color(0xFFFDECEC), // Very soft red tone
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.red.shade100,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.red[800]),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
