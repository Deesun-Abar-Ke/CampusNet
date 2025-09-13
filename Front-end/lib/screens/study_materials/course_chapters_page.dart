import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _notesFuture = StudyMaterialsService.fetchNotes(widget.courseId);
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _notesFuture = StudyMaterialsService.fetchNotes(widget.courseId);
    });
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
                  Navigator.pop(context);
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

  void _openFile(String filename) {
    final url = '$baseUrl/static/note.pdf'; // default PDF
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewPage(url: url, title: filename),
      ),
    );
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Notes list
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _notesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final notes = snapshot.data ?? [];
                final filteredNotes = notes.where((note) {
                  final filename = (note['filename'] ?? '').toString().toLowerCase();
                  return filename.contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredNotes.isEmpty) {
                  return const Center(child: Text('No notes found.'));
                }

                return ListView.builder(
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    final filename = note['filename'] ?? '';

                    return GestureDetector(
                      onLongPress: () {
                        _showDeleteDialog(index, filteredNotes);
                      },
                      child: ListTile(
                        leading: Icon(getFileIcon(filename)),
                        title: Text(filename),
                        onTap: () => _openFile(filename),
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
        onPressed: () async {
          final uploaded = await showDialog<bool>(
            context: context,
            builder: (_) => UploadNoteDialog(courseId: widget.courseId),
          );

          if (uploaded == true) {
            _refreshNotes();
          }
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}

// ----------------- PDF VIEW PAGE -----------------
class PdfViewPage extends StatelessWidget {
  final String url;
  final String title;

  const PdfViewPage({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)), // shows clicked chapter name
      body: SfPdfViewer.network(url),
    );
  }
}
