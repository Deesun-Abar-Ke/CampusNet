// lib/screens/study_materials/study_materials_home.dart
import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'course_chapters_page.dart';

class StudyMaterialsHome extends StatefulWidget {
  const StudyMaterialsHome({Key? key}) : super(key: key);

  @override
  State<StudyMaterialsHome> createState() => _StudyMaterialsHomeState();
}

class _StudyMaterialsHomeState extends State<StudyMaterialsHome> {
  String searchQuery = '';
  List<String> allCourses = [];

  @override
  void initState() {
    super.initState();
    // Populate allCourses from departments
    for (var dept in departments) {
      allCourses.addAll(dept['courses'] as List<String>);
    }
  }

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
      'name': 'Chemical Engineering',
      'icon': Icons.science,
      'courses': [
        'Chemistry Fundamentals (CHEM - 101)',
        'Organic Chemistry',
        'Inorganic Chemistry',
      ],
    },
    {
      'name': 'Architecture',
      'icon': Icons.calculate,
      'courses': ['Linear Algebra', 'Calculus', 'Discrete Mathematics'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = allCourses
        .where(
          (course) => course.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('Study Materials'),
        showBackButton: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.folder,
                      color: Colors.teal[600],
                      size: 28,
                    ),
                    title: Text(
                      filtered[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CourseChaptersPage(courseName: filtered[index]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCourse,
        backgroundColor: Colors.teal,
        tooltip: 'Add New Course',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewCourse() {
    // TODO: Implement adding new course functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: const Text('This feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
