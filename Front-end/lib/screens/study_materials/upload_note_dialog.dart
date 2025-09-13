import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/study_materials_service.dart';
import '../../config.dart'; // baseUrl if needed

class UploadNoteDialog extends StatefulWidget {
  final int courseId;

  const UploadNoteDialog({super.key, required this.courseId});

  @override
  State<UploadNoteDialog> createState() => _UploadNoteDialogState();
}

class _UploadNoteDialogState extends State<UploadNoteDialog> {
  bool _isUploading = false;

  Future<void> _uploadNote(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx'],
      );

      if (result == null) return; // user canceled

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      setState(() => _isUploading = true);

      // Upload file to backend and get accessible file URL
      final uploadedFileUrl = await uploadFileToBackend(filePath, fileName);

      // Call your API to save note info
      await StudyMaterialsService.uploadNote(
        filename: fileName,
        fileUrl: uploadedFileUrl,
        fileType: fileName.split('.').last,
        courseId: widget.courseId,
      );

      if (mounted) {
        Navigator.pop(context, true); // success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, false); // failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Replace with actual file upload logic
  Future<String> uploadFileToBackend(String path, String filename) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate delay
    return '/static/uploads/$filename';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Note'),
      content: _isUploading
          ? SizedBox(
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Uploading... Please wait'),
          ],
        ),
      )
          : const Text('Pick a file from your device to upload.'),
      actions: !_isUploading
          ? [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Select File'),
              onPressed: () => _uploadNote(context),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ]
          : null,
    );
  }
}
