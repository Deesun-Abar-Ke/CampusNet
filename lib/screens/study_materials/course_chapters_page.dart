import 'package:flutter/material.dart';
import '../../services/study_materials_service.dart';
import 'upload_note_dialog.dart';

class CourseChaptersPage extends StatefulWidget {
  final int courseId;
  final String courseName;

  const CourseChaptersPage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<CourseChaptersPage> createState() => _CourseChaptersPageState();
}

class _CourseChaptersPageState extends State<CourseChaptersPage> {
  late Future<List<dynamic>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = StudyMaterialsService.fetchNotes(widget.courseId);
  }

  IconData getFileIcon(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return Icons.slideshow;
    }
    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    }
    return Icons.insert_drive_file;
  }

  void _showDeleteDialog(int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Delete this file"),
                onTap: () {
                  // TODO: implement delete API if available
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _notesFuture = StudyMaterialsService.fetchNotes(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return const Center(child: Text('No notes available.'));
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final filename = note['filename'] ?? '';
              return GestureDetector(
                onLongPress: () => _showDeleteDialog(index),
                child: ListTile(
                  leading: Icon(getFileIcon(filename)),
                  title: Text(filename),
                  onTap: () {
                    // TODO: open note['file_url']
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final uploadedFilePath = await showDialog<String>(
            context: context,
            builder: (_) => UploadNoteDialog(courseId: widget.courseId),
          );
          if (uploadedFilePath != null) {
            _refreshNotes();
          }
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
