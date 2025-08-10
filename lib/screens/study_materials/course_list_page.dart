import 'package:flutter/material.dart';
import '../../services/study_materials_service.dart';
import 'course_chapters_page.dart';

class CourseListPage extends StatefulWidget {
  final int departmentId;
  final String departmentName;

  const CourseListPage({
    Key? key,
    required this.departmentId,
    required this.departmentName,
  }) : super(key: key);

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  late Future<List<dynamic>> _coursesFuture;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _coursesFuture = StudyMaterialsService.fetchCourses(widget.departmentId);
  }

  Future<void> _refreshCourses() async {
    setState(() {
      _coursesFuture = StudyMaterialsService.fetchCourses(widget.departmentId);
    });
  }

  Future<void> _showAddCourseDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Course"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Course Name",
            hintText: "e.g., Data Structures",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final courseName = controller.text.trim();
              if (courseName.isEmpty) return;

              try {
                await StudyMaterialsService.addCourse(
                  name: courseName,
                  departmentId: widget.departmentId,
                );
                Navigator.pop(context);
                _refreshCourses();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Course added successfully!")),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to add course: $e")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _coursesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final courses = snapshot.data ?? [];

                final filtered = courses.where((course) {
                  final courseName =
                  (course['name'] ?? '').toString().toLowerCase();
                  return courseName.contains(searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No courses found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(course['name'] ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseChaptersPage(
                              courseId: course['id'],
                              courseName: course['name'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        tooltip: 'Add New Course',
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
