// lib/screens/messages/group_resources/group_resources_page.dart
import 'package:flutter/material.dart';
<<<<<<< HEAD:Front-end/lib/screens/study_materials/group_resources_page.dart
import '../../widgets/common_app_bar.dart';
import '../chatbot_page.dart';
=======
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../chatbot_page.dart';
import 'add_member_page.dart';
import 'view_members_page.dart';
>>>>>>> fb6ef7a3506d68d62b13e9d68a98d03b1277af89:Front-end/lib/screens/messages/group_resources/group_resources_page.dart

class Folder {
  final String name;
  final List<Folder> subFolders;
  final List<ResourceFile> files;
  
  Folder({
    required this.name,
    this.subFolders = const [],
    this.files = const [],
  });
}

class ResourceFile {
  final String name;
  final String type;
  final String size;
  final String uploadedBy;
  final String uploadDate;
  final IconData icon;
  final Color color;
  
  ResourceFile({
    required this.name,
    required this.type,
    required this.size,
    required this.uploadedBy,
    required this.uploadDate,
    required this.icon,
    required this.color,
  });
}

class GroupResourcesPage extends StatefulWidget {
  final String groupName;
  final List<String>? initialPath;

  const GroupResourcesPage({
    super.key,
    required this.groupName,
    this.initialPath,
  });

  @override
  State<GroupResourcesPage> createState() => _GroupResourcesPageState();
}

class _GroupResourcesPageState extends State<GroupResourcesPage> {
  List<String> currentPath = [];
  late List<Folder> rootFolders;

  @override
  void initState() {
    super.initState();
    _initializeFolders();
    
    // Set initial path if provided
    if (widget.initialPath != null) {
      currentPath = List<String>.from(widget.initialPath!);
    }
  }

  void _initializeFolders() {
    // Sample nested folder structure for Compiler group
    if (widget.groupName.contains('Compiler') || widget.groupName.contains('CSE 303')) {
      rootFolders = [
        Folder(
          name: 'SecA',
          subFolders: [
            Folder(
              name: 'CT1',
              files: [
                ResourceFile(
                  name: 'CT1 Questions.pdf',
                  type: 'pdf',
                  size: '2.1 MB',
                  uploadedBy: 'Prof. Rahman',
                  uploadDate: '2 days ago',
                  icon: Icons.picture_as_pdf,
                  color: Colors.red,
                ),
                ResourceFile(
                  name: 'CT1 Solutions.docx',
                  type: 'docx',
                  size: '1.5 MB',
                  uploadedBy: 'Ahmed Hassan',
                  uploadDate: '1 day ago',
                  icon: Icons.description,
                  color: Colors.blue,
                ),
              ],
            ),
            Folder(
              name: 'CT2',
              files: [
                ResourceFile(
                  name: 'CT2 Preparation Notes.pdf',
                  type: 'pdf',
                  size: '3.2 MB',
                  uploadedBy: 'Sarah Khan',
                  uploadDate: '3 days ago',
                  icon: Icons.picture_as_pdf,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
        Folder(
          name: 'SecB',
          subFolders: [
            Folder(
              name: 'CT1',
              files: [
                ResourceFile(
                  name: 'CT1 Practice Problems.pdf',
                  type: 'pdf',
                  size: '1.8 MB',
                  uploadedBy: 'Nadia Rahman',
                  uploadDate: '4 days ago',
                  icon: Icons.picture_as_pdf,
                  color: Colors.red,
                ),
              ],
            ),
            Folder(
              name: 'CT2',
              files: [
                ResourceFile(
                  name: 'CT2 Study Guide.docx',
                  type: 'docx',
                  size: '2.5 MB',
                  uploadedBy: 'Karim Uddin',
                  uploadDate: '5 days ago',
                  icon: Icons.description,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
        Folder(
          name: 'General Resources',
          files: [
            ResourceFile(
              name: 'Syllabus.pdf',
              type: 'pdf',
              size: '0.8 MB',
              uploadedBy: 'Prof. Rahman',
              uploadDate: '1 week ago',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
            ),
            ResourceFile(
              name: 'Course Outline.docx',
              type: 'docx',
              size: '1.2 MB',
              uploadedBy: 'Prof. Rahman',
              uploadDate: '1 week ago',
              icon: Icons.description,
              color: Colors.blue,
            ),
          ],
        ),
      ];
    } else {
      // Default structure for other groups
      rootFolders = [
        Folder(
          name: 'Lectures',
          files: [
            ResourceFile(
              name: 'Lecture 1 - Introduction.pdf',
              type: 'pdf',
              size: '2.5 MB',
              uploadedBy: 'Prof. Rahman',
              uploadDate: '2 days ago',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
            ),
          ],
        ),
        Folder(
          name: 'Assignments',
          files: [
            ResourceFile(
              name: 'Assignment 1.docx',
              type: 'docx',
              size: '1.2 MB',
              uploadedBy: 'Ahmed Hassan',
              uploadDate: '1 week ago',
              icon: Icons.description,
              color: Colors.blue,
            ),
          ],
        ),
      ];
    }
  }

  List<Folder> getCurrentFolders() {
    List<Folder> folders = rootFolders;
    for (String pathElement in currentPath) {
      folders = folders.firstWhere((folder) => folder.name == pathElement).subFolders;
    }
    return folders;
  }

  List<ResourceFile> getCurrentFiles() {
    if (currentPath.isEmpty) {
      return [];
    }
    
    List<Folder> folders = rootFolders;
    for (int i = 0; i < currentPath.length - 1; i++) {
      folders = folders.firstWhere((folder) => folder.name == currentPath[i]).subFolders;
    }
    
    return folders.firstWhere((folder) => folder.name == currentPath.last).files;
  }

  @override
  Widget build(BuildContext context) {
    final currentFolders = getCurrentFolders();
    final currentFiles = getCurrentFiles();
    
    return PopScope(
      canPop: currentPath.isEmpty,
      onPopInvoked: (didPop) {
        if (!didPop && currentPath.isNotEmpty) {
          setState(() {
            currentPath.removeLast();
          });
        }
      },
      child: Scaffold(
      appBar: CommonAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Group Resources',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        showBackButton: true,
        centerTitle: false,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ResourceSearchDelegate(_getAllFiles()),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_member',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Add Member'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_members',
                child: Row(
                  children: [
                    Icon(Icons.group, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('View Members'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_date',
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Sort by Date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_type',
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Sort by Type'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'add_member') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMemberPage(groupName: widget.groupName),
                  ),
                );
              } else if (value == 'view_members') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewMembersPage(groupName: widget.groupName),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sorting by ${value.toString().split('_')[1]}')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb Navigation
          if (currentPath.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          currentPath.clear();
                        });
                      },
                      child: const Text(
                        'Home',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    for (int i = 0; i < currentPath.length; i++) ...[
                      const Text(' > '),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            currentPath = currentPath.sublist(0, i + 1);
                          });
                        },
                        child: Text(
                          currentPath[i],
                          style: TextStyle(
                            color: i == currentPath.length - 1 ? Colors.black : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          
          // Folders and Files List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Folders
                ...currentFolders.map((folder) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF3E5F5),
                      child: Icon(Icons.folder, color: Colors.deepPurple),
                    ),
                    title: Text(
                      folder.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('${folder.subFolders.length + folder.files.length} items'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'copy_folder_ref',
                              child: const Row(
                                children: [
                                  Icon(Icons.link, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Copy Folder Ref'),
                                ],
                              ),
                              onTap: () => _copyFolderReference(context, folder),
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        currentPath.add(folder.name);
                      });
                    },
                  ),
                )),
                
                // Files
                ...currentFiles.map((file) => ResourceFileTile(
                  file: file,
                  onTap: () => _openResource(file),
                  onDownload: () => _downloadResource(file),
                  onCopyReference: () => _copyReference(context, file),
                )),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      ),
    );
  }

  List<ResourceFile> _getAllFiles() {
    List<ResourceFile> allFiles = [];
    
    void collectFiles(List<Folder> folders) {
      for (var folder in folders) {
        allFiles.addAll(folder.files);
        collectFiles(folder.subFolders);
      }
    }
    
    collectFiles(rootFolders);
    return allFiles;
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.teal),
              title: const Text('Upload File'),
              subtitle: const Text('Add a new document or file'),
              onTap: () {
                Navigator.pop(context);
                _showUploadDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder, color: Colors.teal),
              title: const Text('Create Folder'),
              subtitle: const Text('Organize resources in folders'),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload File',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what you want to upload',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: const Color(0xFF25D366),
                  onTap: () => _handleCameraUpload(context),
                ),
                _buildUploadOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: const Color(0xFF128C7E),
                  onTap: () => _handleGalleryUpload(context),
                ),
                _buildUploadOption(
                  icon: Icons.description,
                  label: 'Document',
                  color: const Color(0xFF075E54),
                  onTap: () => _handleDocumentUpload(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    String folderName = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'e.g., Assignments, Lectures',
          ),
          onChanged: (value) => folderName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: folderName.isNotEmpty
                ? () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Folder "$folderName" created!')),
                    );
                  }
                : null,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon, 
                color: Colors.white, 
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCameraUpload(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo captured: ${image.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Here you would typically upload the file to your server
        // For now, we'll just show a placeholder
        _showUploadSuccess(context, image.name, 'Image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to access camera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleGalleryUpload(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${image.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Here you would typically upload the file to your server
        _showUploadSuccess(context, image.name, 'Image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to access gallery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDocumentUpload(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document selected: ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Here you would typically upload the file to your server
        _showUploadSuccess(context, file.name, 'Document');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadSuccess(BuildContext context, String fileName, String fileType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Upload Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$fileType uploaded successfully!'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    fileType == 'Image' ? Icons.image : Icons.description,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Refresh the file list here if needed
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openResource(ResourceFile resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${resource.name}')),
    );
  }

  void _shareResource(ResourceFile resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${resource.name}')),
    );
  }

  void _downloadResource(ResourceFile resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${resource.name}')),
    );
  }

  void _copyFolderReference(BuildContext context, Folder folder) {
    // Instead of navigating, just go back and add reference to chat
    Navigator.popUntil(context, (route) => route.settings.name == '/group_chat' || route.isFirst);
    
    // Show confirmation that folder reference was copied
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Folder reference copied: ${folder.name}')),
    );
  }

  void _copyReference(BuildContext context, ResourceFile file) {
    // Instead of navigating, just go back and add reference to chat
    Navigator.popUntil(context, (route) => route.settings.name == '/group_chat' || route.isFirst);
    
    // Show confirmation that reference was copied
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reference copied: ${file.name}')),
    );
  }
}

class ResourceFileTile extends StatelessWidget {
  final ResourceFile file;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onCopyReference;

  const ResourceFileTile({
    super.key,
    required this.file,
    required this.onTap,
    required this.onDownload,
    required this.onCopyReference,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: file.color.withOpacity(0.1),
          child: Icon(file.icon, color: file.color),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${file.size} • ${file.type.toUpperCase()}'),
            Text(
              'Uploaded by ${file.uploadedBy} • ${file.uploadDate}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'ask_ai',
              child: const Row(
                children: [
                  Icon(Icons.psychology, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('Ask AI'),
                ],
              ),
              onTap: () => _askAI(context, file),
            ),
            PopupMenuItem(
              value: 'download',
              onTap: onDownload,
              child: const Row(
                children: [
                  Icon(Icons.download, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'copy_reference',
              onTap: onCopyReference,
              child: const Row(
                children: [
                  Icon(Icons.link, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Copy Ref'),
                ],
              ),
            ),
<<<<<<< HEAD:Front-end/lib/screens/study_materials/group_resources_page.dart
            PopupMenuItem(
              value: 'share',
              onTap: onShare,
              child: const Row(
                children: [
                  Icon(Icons.share, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
=======
>>>>>>> fb6ef7a3506d68d62b13e9d68a98d03b1277af89:Front-end/lib/screens/messages/group_resources/group_resources_page.dart
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _askAI(BuildContext context, ResourceFile file) {
    // Direct navigation to chatbot page using proper navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatbotPage(),
      ),
    );
  }

  void _navigateToAIChatbot(BuildContext context, ResourceFile file) {
    // Try to navigate directly to chatbot page
    try {
      Navigator.pushNamed(context, '../chatbot_page.dart');
    } catch (e) {
      // If direct navigation fails, show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening AI Chat about ${file.name}...'),
          duration: const Duration(seconds: 2),
        ),
      );
      // You can add proper navigation here when chatbot route is configured
    }
  }

  void _shareInChat(BuildContext context, String referenceText, String fullReference, ResourceFile file) {
    // This would add the reference to the chat
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share in Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will share the following reference in the group chat:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    referenceText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fullReference,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reference shared in group chat!')),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}



class ResourceSearchDelegate extends SearchDelegate {
  final List<ResourceFile> resources;

  ResourceSearchDelegate(this.resources);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = resources
        .where((resource) =>
            resource.name.toLowerCase().contains(query.toLowerCase()) ||
            resource.uploadedBy.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final resource = results[index];
        return ResourceFileTile(
          file: resource,
          onTap: () => close(context, resource),
          onDownload: () {},
          onCopyReference: () {},
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = resources
        .where((resource) =>
            resource.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final resource = suggestions[index];
        return ListTile(
          leading: Icon(resource.icon, color: resource.color),
          title: Text(resource.name),
          subtitle: Text('by ${resource.uploadedBy}'),
          onTap: () {
            query = resource.name;
            showResults(context);
          },
        );
      },
    );
  }
}
