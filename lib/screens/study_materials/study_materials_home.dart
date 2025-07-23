// lib/screens/study_materials/study_materials_home.dart
import 'package:flutter/material.dart';
import 'course_list_page.dart';

class StudyMaterialsHome extends StatelessWidget {
  const StudyMaterialsHome({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> departments = const [
    {
      'name': 'Computer Science & Engineering',
      'icon': Icons.computer,
      'courses': [
        'Artificial Intelligence',
        'C Language Theory',
        'Compilers (CSE 303)',
        'Data Structures',
      ],
    },
    {
      'name': 'Chemistry',
      'icon': Icons.science,
      'courses': [
        'Chemistry Fundamentals (CHEM - 101)',
        'Organic Chemistry',
        'Inorganic Chemistry',
      ],
    },
    {
      'name': 'Mathematics',
      'icon': Icons.calculate,
      'courses': [
        'Linear Algebra',
        'Calculus',
        'Discrete Mathematics',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: departments.map((dept) {
            return _buildTile(
              context,
              icon: dept['icon'],
              label: dept['name'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseListPage(
                      departmentName: dept['name'],
                      courses: List<String>.from(dept['courses']),
                    ),
                  ),
                );
              },
            );
          }).toList(),
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
      color: const Color(0xFFECEBFD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.deepPurple.shade100,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.deepPurple[700]),
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
