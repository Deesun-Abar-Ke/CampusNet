import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import '../landing_page.dart';
import 'upload_note_dialog.dart';

class CourseChaptersPage extends StatelessWidget {
  final String courseName;

  const CourseChaptersPage({Key? key, required this.courseName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> notes = [
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: courseName, showBackButton: true),

      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return ListTile(
            leading: Icon(getFileIcon(note)),
            title: Text(note),
            //trailing: const Icon(Icons.people), // shared icon
            onTap: () {
              // TODO: Open file viewer if implemented
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const UploadNoteDialog(),
          );
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
