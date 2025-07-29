// lib/screens/study_materials/department_courses_page.dart
import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'course_chapters_page.dart';

class DepartmentCoursesPage extends StatefulWidget {
  final String departmentName;
  final List<String> courses;

  const DepartmentCoursesPage({
    Key? key,
    required this.departmentName,
    required this.courses,
  }) : super(key: key);

  @override
  State<DepartmentCoursesPage> createState() => _DepartmentCoursesPageState();
}

class _DepartmentCoursesPageState extends State<DepartmentCoursesPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.courses
        .where(
          (course) => course.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: CommonAppBar(title: Text(widget.departmentName), showBackButton: true),
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
                      Icons.book,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: Text('Add a new course to ${widget.departmentName}'),
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
