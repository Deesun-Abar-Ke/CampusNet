// lib/screens/study_materials/course_list_page.dart
import 'package:flutter/material.dart';
import 'course_chapters_page.dart';

class CourseListPage extends StatefulWidget {
  final String departmentName;
  final List<String> courses;

  const CourseListPage({
    super.key,
    required this.departmentName,
    required this.courses,
  });

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  late List<String> courseList;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    courseList = List.from(widget.courses);
  }

  void _addNewCourse() {
    showDialog(
      context: context,
      builder: (context) {
        String newCourse = '';
        return AlertDialog(
          title: const Text('Add New Course'),
          content: TextField(
            onChanged: (val) => newCourse = val,
            decoration: const InputDecoration(hintText: 'Enter course name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newCourse.trim().isNotEmpty) {
                  setState(() => courseList.add(newCourse.trim()));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = courseList
        .where((course) => course.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.departmentName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(filtered[index]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseChaptersPage(courseName: filtered[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCourse,
        tooltip: 'Add New Course',
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
