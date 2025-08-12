// lib/screens/study_materials/department_courses_page.dart
import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'course_chapters_page.dart';

class DepartmentCoursesPage extends StatefulWidget {
  final String departmentName;
  final List<String> courses;

  const DepartmentCoursesPage({
    super.key,
    required this.departmentName,
    required this.courses,
  });

  @override
  State<DepartmentCoursesPage> createState() => _DepartmentCoursesPageState();
}

class _DepartmentCoursesPageState extends State<DepartmentCoursesPage> {
  String searchQuery = '';
  late List<Map<String, dynamic>> courseData;

  @override
  void initState() {
    super.initState();
    // Convert the simple string list to a more complex data structure
    courseData = widget.courses.map((courseName) => {
      'name': courseName,
      'folders': <Map<String, dynamic>>[],
      'files': <Map<String, dynamic>>[],
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = courseData
        .where(
          (course) => course['name'].toLowerCase().contains(searchQuery.toLowerCase()),
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
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // Course Count Info
          if (filtered.length != courseData.length)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${filtered.length} of ${courseData.length} courses',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final course = filtered[index];
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
                      course['name'],
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
                              CourseChaptersPage(courseName: course['name']),
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        tooltip: 'Add New Course',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewCourse() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Course to ${widget.departmentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the name of the new course:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Course name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  courseData.add({
                    'name': controller.text.trim(),
                    'folders': <Map<String, dynamic>>[],
                    'files': <Map<String, dynamic>>[],
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Course "${controller.text.trim()}" added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Add Course'),
          ),
        ],
      ),
    );
  }
}
