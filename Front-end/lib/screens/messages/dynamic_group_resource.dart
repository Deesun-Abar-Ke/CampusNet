// lib/screens/messages/dynamic_group_resource.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'group_chat_screen.dart';
import 'dart:io';
import '../../widgets/common_app_bar.dart';
import '../../services/group_resource_service.dart';
import '../chatbot_page.dart';
import '../home/landing_page.dart';
import '../../config.dart';

class DynamicGroupResourceFolder {
  final int id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final int itemCount;

  DynamicGroupResourceFolder({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.itemCount,
  });

  factory DynamicGroupResourceFolder.fromJson(Map<String, dynamic> json) {
    return DynamicGroupResourceFolder(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      itemCount: json['item_count'] ?? 0,
    );
  }
}

class DynamicGroupResourceFile {
  final int id;
  final String name;
  final String originalFilename;
  final String fileType;
  final int fileSize;
  final String fileSizeReadable;
  final String fileUrl;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? description;
  final String? mimeType;

  DynamicGroupResourceFile({
    required this.id,
    required this.name,
    required this.originalFilename,
    required this.fileType,
    required this.fileSize,
    required this.fileSizeReadable,
    required this.fileUrl,
    required this.uploadedBy,
    required this.uploadedAt,
    this.description,
    this.mimeType,
  });

  factory DynamicGroupResourceFile.fromJson(Map<String, dynamic> json) {
    return DynamicGroupResourceFile(
      id: json['id'],
      name: json['name'],
      originalFilename: json['original_filename'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      fileSizeReadable: json['file_size_readable'],
      fileUrl: json['file_url'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      description: json['description'],
      mimeType: json['mime_type'],
    );
  }

  IconData get icon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get color {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.deepPurple;
      case 'mp3':
      case 'wav':
        return Colors.pink;
      case 'zip':
      case 'rar':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

class DynamicGroupResourcePage extends StatefulWidget {
  final String groupName;
  final int conversationId;
  final List<Map<String, dynamic>>? initialPath;

  const DynamicGroupResourcePage({
    super.key,
    required this.groupName,
    required this.conversationId,
    this.initialPath,
  });

  @override
  State<DynamicGroupResourcePage> createState() => _DynamicGroupResourcePageState();
}

class _DynamicGroupResourcePageState extends State<DynamicGroupResourcePage> {
  List<Map<String, dynamic>> currentPath = [];
  List<DynamicGroupResourceFolder> folders = [];
  List<DynamicGroupResourceFile> files = [];
  bool isLoading = true;
  String? errorMessage;
  int? currentFolderId;

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null) {
      currentPath = List<Map<String, dynamic>>.from(widget.initialPath!);
      if (currentPath.isNotEmpty) {
        currentFolderId = currentPath.last['id'];
      }
    }
    _loadResources();
  }

  Future<void> _loadResources() async {
    print('DEBUG - Loading resources for conversation ID: ${widget.conversationId}');
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await GroupResourceService.getFolders(
        widget.conversationId,
        parentFolderId: currentFolderId,
      );

      setState(() {
        folders = (data['folders'] as List)
            .map((folder) => DynamicGroupResourceFolder.fromJson(folder))
            .toList();
        
        files = (data['files'] as List)
            .map((file) => DynamicGroupResourceFile.fromJson(file))
            .toList();
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _createFolder() async {
    String folderName = '';
    String description = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Folder Name *',
                  hintText: 'e.g., Assignments, Lectures',
                ),
                onChanged: (value) => setState(() => folderName = value),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of folder contents',
                ),
                maxLines: 2,
                onChanged: (value) => setState(() => description = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: folderName.trim().isNotEmpty
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && folderName.trim().isNotEmpty) {
      try {
        await GroupResourceService.createFolder(
          widget.conversationId,
          folderName.trim(),
          parentFolderId: currentFolderId,
          description: description.trim().isNotEmpty ? description.trim() : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Folder "$folderName" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadResources();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating folder: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _uploadFile(File file, {String? description}) async {
    if (currentFolderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a folder first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Uploading file...'),
            ],
          ),
        ),
      );

      await GroupResourceService.uploadFile(
        widget.conversationId,
        currentFolderId!,
        file,
        description: description,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadResources();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentPath.isEmpty,
      onPopInvoked: (didPop) {
        if (!didPop && currentPath.isNotEmpty) {
          setState(() {
            currentPath.removeLast();
            currentFolderId = currentPath.isNotEmpty ? currentPath.last['id'] : null;
          });
          _loadResources();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.groupName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                'Group Resources',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (currentPath.isNotEmpty) {
                // Navigate up one folder level
                setState(() {
                  currentPath.removeLast();
                  currentFolderId = currentPath.isNotEmpty ? currentPath.last['id'] : null;
                });
                _loadResources();
              } else {
                // At root level, go back to group chat
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (route) => false,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: DynamicResourceSearchDelegate(files, widget.conversationId),
                );
              },
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sorting by ${value.toString().split('_')[1]}')),
                );
                // TODO: Implement sorting logic
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
                            currentFolderId = null;
                          });
                          _loadResources();
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
                              currentFolderId = currentPath.last['id'];
                            });
                            _loadResources();
                          },
                          child: Text(
                            currentPath[i]['name'],
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
            
            // Content Area
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading resources',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadResources,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Folders
                            ...folders.map((folder) => Card(
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${folder.itemCount} items'),
                                    if (folder.description != null)
                                      Text(
                                        folder.description!,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    Text(
                                      'Created by ${folder.createdBy}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
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
                                              Text('Post Reference'),
                                            ],
                                          ),
                                          onTap: () => _copyFolderReference(context, folder),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete_folder',
                                          child: const Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete Folder'),
                                            ],
                                          ),
                                          onTap: () => _deleteFolder(folder),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () async {
                                  try {
                                    final pathData = await GroupResourceService.getFolderPath(
                                      widget.conversationId,
                                      folder.id,
                                    );
                                    
                                    setState(() {
                                      currentPath = pathData;
                                      currentFolderId = folder.id;
                                    });
                                    _loadResources();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error navigating to folder: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            )),
                            
                            // Files
                            ...files.map((file) => DynamicResourceFileTile(
                              file: file,
                              onTap: () => _openResource(file),
                              onDownload: () => _downloadResource(file),
                              onCopyReference: () => _copyReference(context, file),
                              onDelete: () => _deleteFile(file),
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
                _createFolder();
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        final file = File(image.path);
        _showFilePreview(file, image.name);
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
        final file = File(image.path);
        _showFilePreview(file, image.name);
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

  void _handleDocumentUpload(context) async {
    Navigator.pop(context);
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        
        if (platformFile.path != null) {
          final file = File(platformFile.path!);
          _showFilePreview(file, platformFile.name);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilePreview(File file, String fileName) {
    String description = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(file.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add a description for this file',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => description = value,
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
              _uploadFile(file, description: description.trim().isNotEmpty ? description.trim() : null);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _openResource(DynamicGroupResourceFile resource) async {
    // Open file directly in browser/viewer - using same logic as group chat
    try {
      var url = resource.fileUrl;
      
      // Fix localhost URLs - replace with configured server IP from Config
      if (url.contains('localhost')) {
        // Extract the server host from Config.baseUrl
        final configUri = Uri.parse(Config.baseUrl);
        final serverHost = '${configUri.host}:${configUri.port}';
        url = url.replaceAll('localhost:5000', serverHost);
      }
      
      final Uri uri = Uri.parse(url);
      
      print('DEBUG: Opening file - Original URL: ${resource.fileUrl}');
      print('DEBUG: Opening file - Fixed URL: $url');
      print('DEBUG: File type: ${resource.fileType}');
      print('DEBUG: Original filename: ${resource.originalFilename}');
      
      // Check if it's a PDF file by URL extension
      final isPdf = url.toLowerCase().contains('.pdf');
      
      if (await canLaunchUrl(uri)) {
        if (isPdf) {
          print('DEBUG: Opening PDF with platformDefault');
          // For PDFs, use platformDefault for better viewing experience
          await launchUrl(uri, mode: LaunchMode.platformDefault).catchError((e) {
            print('DEBUG: platformDefault failed, trying external app: $e');
            // Fallback to external application if platformDefault fails
            return launchUrl(uri, mode: LaunchMode.externalApplication);
          });
        } else {
          print('DEBUG: Opening non-PDF file with platformDefault');
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        print('DEBUG: Cannot launch URL');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      print('DEBUG: Exception in _openResource: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  void _downloadResource(DynamicGroupResourceFile resource) async {
    try {
      await GroupResourceService.downloadFile(
        resource.fileUrl.split('/').last,
        resource.originalFilename,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded ${resource.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyFolderReference(BuildContext context, DynamicGroupResourceFolder folder) {
    // Build folder reference data
    final ref = {
      'type': 'folder',
      'folder_id': folder.id,
      'folder_name': folder.name,
      'conversation_id': widget.conversationId,
      'folder_path': [...currentPath, {'id': folder.id, 'name': folder.name}],
    };
    
    // Navigate to group chat with initial reference
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          conversationId: widget.conversationId,
          groupName: widget.groupName,
          memberCount: 0,
          avatar: '',
          courseFolder: '',
          initialReference: ref,
        ),
      ),
    );
  }

  void _copyReference(BuildContext context, DynamicGroupResourceFile file) {
    // Build reference data
    final ref = {
      'type': 'file',
      'file_id': file.id,
      'file_name': file.name,
      'file_url': file.fileUrl,
      'file_type': file.fileType,
      'conversation_id': widget.conversationId,
      'folder_path': currentPath,
    };
    
    // Navigate to group chat with initial reference
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          conversationId: widget.conversationId,
          groupName: widget.groupName,
          memberCount: 0,
          avatar: '',
          courseFolder: '',
          initialReference: ref,
        ),
      ),
    );
  }

  void _deleteFolder(DynamicGroupResourceFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupResourceService.deleteFolder(widget.conversationId, folder.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadResources();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting folder: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteFile(DynamicGroupResourceFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupResourceService.deleteFile(widget.conversationId, file.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadResources();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class DynamicResourceFileTile extends StatelessWidget {
  final DynamicGroupResourceFile file;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onCopyReference;
  final VoidCallback onDelete;

  const DynamicResourceFileTile({
    super.key,
    required this.file,
    required this.onTap,
    required this.onDownload,
    required this.onCopyReference,
    required this.onDelete,
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
            Text('${file.fileSizeReadable} • ${file.fileType.toUpperCase()}'),
            Text(
              'Uploaded by ${file.uploadedBy} • ${_formatDate(file.uploadedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (file.description != null && file.description!.isNotEmpty)
              Text(
                file.description!,
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
              value: 'post_reference',
              onTap: onCopyReference,
              child: const Row(
                children: [
                  Icon(Icons.link, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Post Reference'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              onTap: () => _shareFile(context, file),
              child: const Row(
                children: [
                  Icon(Icons.share, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              onTap: onDelete,
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _askAI(BuildContext context, DynamicGroupResourceFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatbotPage(),
      ),
    );
  }

  void _shareFile(BuildContext context, DynamicGroupResourceFile file) {
    final fileUrl = file.fileUrl;
    final fileName = file.name;
    final fileInfo = '${file.name}\nSize: ${file.fileSizeReadable}\nType: ${file.fileType.toUpperCase()}';
    
    Share.share(
      '$fileInfo\n\nDownload: $fileUrl',
      subject: 'Shared from CampusNet: $fileName',
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class DynamicResourceSearchDelegate extends SearchDelegate {
  final List<DynamicGroupResourceFile> resources;
  final int conversationId;

  DynamicResourceSearchDelegate(this.resources, this.conversationId);

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
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a search term'),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: GroupResourceService.searchResources(conversationId, query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final data = snapshot.data!;
        final folders = (data['folders'] as List)
            .map((folder) => DynamicGroupResourceFolder.fromJson(folder))
            .toList();
        final files = (data['files'] as List)
            .map((file) => DynamicGroupResourceFile.fromJson(file))
            .toList();
        
        if (folders.isEmpty && files.isEmpty) {
          return const Center(
            child: Text('No results found'),
          );
        }

        return ListView(
          children: [
            // Folders
            ...folders.map((folder) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF3E5F5),
                  child: Icon(Icons.folder, color: Colors.deepPurple),
                ),
                title: Text(folder.name),
                subtitle: Text(folder.description ?? 'No description'),
                onTap: () => close(context, folder),
              ),
            )),
            
            // Files
            ...files.map((file) => DynamicResourceFileTile(
              file: file,
              onTap: () => close(context, file),
              onDownload: () {},
              onCopyReference: () {},
              onDelete: () {},
            )),
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = resources
        .where((resource) =>
            resource.name.toLowerCase().contains(query.toLowerCase()))
        .take(5)
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
