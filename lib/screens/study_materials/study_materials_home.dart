import 'package:flutter/material.dart';
import 'course_chapters_page.dart';

class StudyMaterialsHome extends StatefulWidget {
  const StudyMaterialsHome({Key? key}) : super(key: key);

  @override
  State<StudyMaterialsHome> createState() => _StudyMaterialsHomeState();
}

class _StudyMaterialsHomeState extends State<StudyMaterialsHome> {
  final List<String> allCourses = [
    'Artificial Intelligence',
    'C Language Theory',
    'Chemistry Fundamentals (CHEM - 101)',
    'Compilers (CSE 303)',
  ];

  String searchQuery = '';

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
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newCourse.trim().isNotEmpty) {
                  setState(() => allCourses.add(newCourse.trim()));
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
    final filtered = allCourses
        .where((course) =>
        course.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
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
                        builder: (_) => CourseChaptersPage(
                          courseName: filtered[index],
                        ),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
