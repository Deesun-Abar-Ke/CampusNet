import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'upload_note_dialog.dart';

class FolderContentsPage extends StatefulWidget {
  final String folderName;
  final List<Map<String, dynamic>> folderItems;

  const FolderContentsPage({
    super.key,
    required this.folderName,
    required this.folderItems,
  });

  @override
  State<FolderContentsPage> createState() => _FolderContentsPageState();
}

class _FolderContentsPageState extends State<FolderContentsPage> {
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.folderItems);
  }

  IconData getFileIcon(String filename) {
    if (filename.endsWith('.ppt') || filename.endsWith('.pptx')) {
      return Icons.slideshow;
    }
    if (filename.endsWith('.mp4') || filename.endsWith('.avi') || filename.endsWith('.mov')) {
      return Icons.video_file;
    }
    if (filename.endsWith('.doc') || filename.endsWith('.docx')) {
      return Icons.description;
    }
    return Icons.picture_as_pdf;
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
      builder: (_) => const UploadNoteDialog(),
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
                  setState(() {
                    items.removeAt(index);
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
      appBar: CommonAppBar(title: Text(widget.folderName), showBackButton: true),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This folder is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add files or folders using the + button',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onLongPress: () => _showDeleteDialog(index),
                  child: ListTile(
                    leading: Icon(
                      item['icon'],
                      color: item['type'] == 'folder' ? Colors.amber[600] : Colors.blue[600],
                    ),
                    title: Text(item['name']),
                    trailing: item['type'] == 'folder' ? const Icon(Icons.chevron_right) : null,
                    onTap: () {
                      if (item['type'] == 'folder') {
                        // Navigate to nested folder contents
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FolderContentsPage(
                              folderName: item['name'],
                              folderItems: item['items'] ?? [],
                            ),
                          ),
                        );
                      } else {
                        // TODO: Implement file open/view
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
