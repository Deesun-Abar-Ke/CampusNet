import 'package:flutter/material.dart';
import '../../services/study_materials_service.dart';
import '../../widgets/common_app_bar.dart';
import 'course_list_page.dart';

class StudyMaterialsHome extends StatefulWidget {
  const StudyMaterialsHome({super.key});

  @override
  State<StudyMaterialsHome> createState() => _StudyMaterialsHomeState();
}

class _StudyMaterialsHomeState extends State<StudyMaterialsHome> {
  late Future<List<dynamic>> _departmentsFuture;

  final List<Color> _tileColors = [
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.orange.shade100,
    Colors.pink.shade100,
    Colors.purple.shade100,
    Colors.teal.shade100,
    Colors.yellow.shade100,
    Colors.cyan.shade100,
    Colors.indigo.shade100,
    Colors.lime.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _departmentsFuture = StudyMaterialsService.fetchDepartments();
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color tileColor,
  }) {
    return Material(
      color: tileColor,
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
      appBar: const CommonAppBar(
        title: Text(
          'Resource Bank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        showBackButton: true,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Get all your study materials in one place!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Departments Grid
            Expanded(
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
                    children: List.generate(departments.length, (index) {
                      final dept = departments[index];
                      final iconData = _mapIconStringToIconData(dept['icon']);
                      final color = _tileColors[index % _tileColors.length];
                      return _buildTile(
                        context: context,
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
                        tileColor: color,
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
