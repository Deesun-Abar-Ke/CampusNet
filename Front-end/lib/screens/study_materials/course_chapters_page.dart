import 'package:flutter/material.dart';
import '../../services/study_materials_service.dart';
import '../../widgets/common_app_bar.dart';
import 'upload_note_dialog.dart';

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
  List<Map<String, dynamic>> items = [];

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

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: const Text('What would you like to add?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addNewFolder();
            },
            child: const Text('Add Folder'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadFile();
            },
            child: const Text('Upload File'),
          ),
        ],
      ),
    );
  }

  void _addNewFolder() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter folder name:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Folder name',
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
                  items.add({
                    'name': controller.text.trim(),
                    'type': 'folder',
                    'icon': Icons.folder,
                    'items': <Map<String, dynamic>>[],
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Folder "${controller.text.trim()}" created!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _uploadFile() async {
    final uploadedFilePath = await showDialog<String>(
      context: context,
      builder: (_) => UploadNoteDialog(courseId: widget.courseId),
    );

    if (uploadedFilePath != null) {
      final filename = uploadedFilePath.split('/').last;
      setState(() {
        items.add({
          'name': filename,
          'type': 'file',
          'icon': getFileIcon(filename),
        });
      });
    }
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
                title: Text("Delete ${items[index]['type']}"),
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
