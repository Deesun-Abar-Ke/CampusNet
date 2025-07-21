// lib/screens/study_materials/upload_note_dialog.dart
import 'package:flutter/material.dart';

class UploadNoteDialog extends StatelessWidget {
  const UploadNoteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Upload Note"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Pick a PDF or PPT file to upload."),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.attach_file),
            label: const Text("Choose File"),
            onPressed: () {
              // TODO: Implement file picker logic
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text("Upload"),
          onPressed: () {
            // TODO: Implement upload logic
          },
        ),
      ],
    );
  }
}
