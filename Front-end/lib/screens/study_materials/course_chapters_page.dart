import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/study_materials_service.dart';
import '../../widgets/common_app_bar.dart';
import 'upload_note_dialog.dart';
import '../../config.dart'; // contains your backend baseUrl

class CourseChaptersPage extends StatefulWidget {
  final int courseId;
  final String courseName;

  const CourseChaptersPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

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

  Future<void> _refreshNotes() async {
    setState(() {
      _notesFuture = StudyMaterialsService.fetchNotes(widget.courseId);
    });
  }

  void _showDeleteDialog(int index, List<dynamic> notes) {
    final note = notes[index];
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text("Delete ${note['filename']}"),
                onTap: () async {
                  Navigator.pop(context); // Close the bottom sheet
                  try {
                    await StudyMaterialsService.deleteNote(note['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note deleted successfully')),
                    );
                    _refreshNotes();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete note: $e')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFile(String? fileUrl) async {
    // Use default PDF if fileUrl is null or empty
    final urlToOpen = (fileUrl == null || fileUrl.isEmpty)
        ? '${Config.baseUrl}/study/notes/default'
        : '${Config.baseUrl}$fileUrl';

    final uri = Uri.parse(urlToOpen);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: Text(
          widget.courseName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        showBackButton: true,
        centerTitle: true,
        backgroundColor: Colors.teal,
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
              final fileUrl = note['file_url'];

              return GestureDetector(
                onLongPress: () {
                  // Only show delete option if current user is uploader
                  final currentUserId = note['uploaded_by']; // You may fetch current JWT user
                  // Here we assume StudyMaterialsService.getCurrentUserId() exists
                  _showDeleteDialog(index, notes);
                },
                child: ListTile(
                  leading: Icon(getFileIcon(filename)),
                  title: Text(filename),
                  onTap: () => _openFile(fileUrl),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show the upload dialog
          final uploaded = await showDialog<bool>(
            context: context,
            builder: (_) => UploadNoteDialog(courseId: widget.courseId),
          );

          // Refresh notes only if upload succeeded
          if (uploaded == true) {
            _refreshNotes();
          }
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
