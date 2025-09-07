import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/study_materials_service.dart';
import '../../config.dart'; // baseUrl if needed

class UploadNoteDialog extends StatelessWidget {
  final int courseId;

  const UploadNoteDialog({super.key, required this.courseId});

  Future<void> _uploadNote(BuildContext context) async {
    try {
      // Pick file from device
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx'],
      );

      if (result == null) return; // User canceled

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      // Upload file to backend and get accessible file URL
      final uploadedFileUrl = await uploadFileToBackend(filePath, fileName);

      // Call your API to save note info
      await StudyMaterialsService.uploadNote(
        filename: fileName,
        fileUrl: uploadedFileUrl,
        fileType: fileName.split('.').last,
        courseId: courseId,
      );

      // Close dialog and notify parent that upload succeeded
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded successfully!')),
      );
    } catch (e) {
      Navigator.pop(context, false); // upload failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  /// Replace this with your actual file upload logic
  Future<String> uploadFileToBackend(String path, String filename) async {
    // TODO: implement actual upload
    // For now, just return a mock URL
    await Future.delayed(const Duration(seconds: 1)); // simulate upload delay
    return '/static/uploads/$filename';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pick a file from your device to upload.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Select File'),
            onPressed: () => _uploadNote(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}
