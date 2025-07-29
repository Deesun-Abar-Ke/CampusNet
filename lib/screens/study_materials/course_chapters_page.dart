import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import '../landing_page.dart';
import 'upload_note_dialog.dart';

class CourseChaptersPage extends StatefulWidget {
  final String courseName;

  const CourseChaptersPage({Key? key, required this.courseName})
    : super(key: key);

  @override
  State<CourseChaptersPage> createState() => _CourseChaptersPageState();
}

class _CourseChaptersPageState extends State<CourseChaptersPage> {
  List<String> notes = [
    'Chapter 1_Final.pptx',
    'Chapter 3.pdf',
    'CSE-303 Chapter-05 Final.pdf',
    'How to install flex in your home computer.pdf',
  ];

    IconData getFileIcon(String filename) {
      if (filename.endsWith('.ppt') || filename.endsWith('.pptx'))
        return Icons.slideshow;
      return Icons.picture_as_pdf;
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
                  setState(() {
                    notes.removeAt(index);
                  });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: Text(widget.courseName), showBackButton: true),

      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return GestureDetector(
            onLongPress: () => _showDeleteDialog(index),
            child: ListTile(
              leading: Icon(getFileIcon(note)),
              title: Text(note),
              onTap: () {
                // TODO: Implement file open/view
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final uploadedFilePath = await showDialog<String>(
            context: context,
            builder: (_) => const UploadNoteDialog(),
          );

          if (uploadedFilePath != null) {
            setState(() {
              notes.add(uploadedFilePath.split('/').last);
            });
          }
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
