// lib/screens/study_materials/group_resources_page.dart
import 'package:flutter/material.dart';

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

  const GroupResourcesPage({
    super.key,
    required this.groupName,
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
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Group Resources',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
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
                value: 'sort_name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'sort_date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'sort_type',
                child: Text('Sort by Type'),
              ),
            ],
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sorting by ${value.toString().split('_')[1]}')),
              );
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
                    trailing: const Icon(Icons.chevron_right),
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
                  onShare: () => _shareResource(file),
                  onDownload: () => _downloadResource(file),
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
    String fileName = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Resource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'File Name',
                hintText: 'e.g., Lecture 5 Notes',
              ),
              onChanged: (value) => fileName = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the file',
              ),
              maxLines: 3,
              onChanged: (value) {
                // Description can be used for additional file metadata
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.teal[700]),
                  const SizedBox(width: 8),
                  const Text('Choose file to upload'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // File picker would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File picker would open here')),
                      );
                    },
                    child: const Text('Browse'),
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
            onPressed: fileName.isNotEmpty
                ? () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$fileName uploaded successfully!')),
                    );
                  }
                : null,
            child: const Text('Upload'),
          ),
        ],
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
}

class ResourceFileTile extends StatelessWidget {
  final ResourceFile file;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  const ResourceFileTile({
    super.key,
    required this.file,
    required this.onTap,
    required this.onShare,
    required this.onDownload,
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
              value: 'open',
              onTap: onTap,
              child: const Row(
                children: [
                  Icon(Icons.open_in_new),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'download',
              onTap: onDownload,
              child: const Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              onTap: onShare,
              child: const Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
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
          onShare: () {},
          onDownload: () {},
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
