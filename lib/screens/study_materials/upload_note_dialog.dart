import 'package:flutter/material.dart';
import '../../services/study_materials_service.dart';

class UploadNoteDialog extends StatelessWidget {
  final int courseId;

  const UploadNoteDialog({super.key, required this.courseId});

  // Make this function async so you can await your uploadNote call
  Future<void> _uploadSampleNote(BuildContext context) async {
    try {
      const backendIP = '192.168.0.103'; // Your PC's local IP
      final fileUrl = 'http://$backendIP:5000/static/note.pdf';

      // Call your existing service method
      await StudyMaterialsService.uploadNote(
        filename: 'note.pdf',
        fileUrl: fileUrl,
        fileType: 'pdf',
        courseId: courseId,
      );

      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded successfully!')),
      );
    } catch (e) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This will upload a sample note for the course.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Sample Note'),
            onPressed: () => _uploadSampleNote(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
