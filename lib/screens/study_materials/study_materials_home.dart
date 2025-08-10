import 'package:flutter/material.dart';
import '../../services/study_materials_service.dart';
import 'course_list_page.dart';

class StudyMaterialsHome extends StatefulWidget {
  const StudyMaterialsHome({Key? key}) : super(key: key);

  @override
  State<StudyMaterialsHome> createState() => _StudyMaterialsHomeState();
}

class _StudyMaterialsHomeState extends State<StudyMaterialsHome> {
  late Future<List<dynamic>> _departmentsFuture;

  @override
  void initState() {
    super.initState();
    _departmentsFuture = StudyMaterialsService.fetchDepartments();
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

  IconData _mapIconStringToIconData(String? iconName) {
    // Simple mapping, add more icons if needed
    switch (iconName) {
      case 'computer':
        return Icons.computer;
      case 'science':
        return Icons.science;
      case 'calculate':
        return Icons.calculate;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<dynamic>>(
          future: _departmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final departments = snapshot.data ?? [];

            if (departments.isEmpty) {
              return const Center(child: Text('No departments found.'));
            }

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: departments.map((dept) {
                final iconData = _mapIconStringToIconData(dept['icon']);
                return _buildTile(
                  context,
                  icon: iconData,
                  label: dept['name'] ?? 'No Name',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseListPage(
                          departmentId: dept['id'],
                          departmentName: dept['name'],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
