import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../blood_bank/blood_bank_home_page.dart';
import '../tuition/tuition_page.dart';
import '../chatbot_page.dart';
import '../messages/messages_page.dart';
import 'profile/profile_page.dart';
import '../study_materials/study_materials_home.dart';
import '../institutional_map/institutional_map_page.dart';
import '../../widgets/feature_icon.dart';
import '../../widgets/social_post_card.dart';
import '../../models/social_models.dart';
import '../../services/social_service.dart';
import '../../services/auth_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? _selectedTag;
  List<SocialPost> _posts = [];
  List<SocialTag> _tags = [];
  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load posts, tags, and user data in parallel
      final results = await Future.wait([
        SocialService.getPosts(tag: _selectedTag),
        SocialService.getPopularTags(),
        AuthService.getCurrentUser(),
      ]);

      if (!mounted) return;

      final postsData = results[0] as List<Map<String, dynamic>>;
      final tagsData = results[1] as List<Map<String, dynamic>>;
      final userData = results[2] as Map<String, dynamic>?;

      setState(() {
        _tags = tagsData.map((tag) => SocialTag(
          id: tag['id'] ?? 0,
          name: tag['name']!,
          color: tag['color']!,
          createdAt: DateTime.now(),
        )).toList();
        _posts = postsData.map((post) => SocialPost.fromJson(post)).toList();
        _currentUser = userData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _refreshPosts() async {
    try {
      print('🔄 Refreshing posts with tag: $_selectedTag');
      final postsData = await SocialService.getPosts(tag: _selectedTag);
      
      if (!mounted) return;
      
      setState(() {
        _posts = postsData.map((post) => SocialPost.fromJson(post)).toList();
        _isLoading = false;  // Stop loading after posts are fetched
      });
      
      print('✅ Loaded ${_posts.length} posts for tag: $_selectedTag');
    } catch (e) {
      print('❌ Error refreshing posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;  // Stop loading on error too
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh posts: $e')),
        );
      }
    }
  }

  void _onTagSelected(String? tag) {
    if (!mounted) return;
    
    print('🏷️ Tag selected: $tag (previous: $_selectedTag)');
    
    setState(() {
      _selectedTag = tag;
      _isLoading = true;  // Show loading state while filtering
    });
    
    print('🔍 Starting to refresh posts for tag: $tag');
    _refreshPosts();
  }

  Widget _buildTagChip(SocialTag tag) {
    final isSelected = tag.name == _selectedTag || (tag.name == 'All' && _selectedTag == null);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        label: Text(tag.name),
        onSelected: (selected) {
          print('🎯 Tag chip clicked: ${tag.name}, selected: $selected');
          if (selected) {
            // Tag is being selected
            final tagName = tag.name == 'All' ? null : tag.name;
            print('🏷️ Selecting tag: $tagName');
            _onTagSelected(tagName);
          } else {
            // Tag is being deselected - default to "All"
            print('🏷️ Deselecting tag, defaulting to All');
            _onTagSelected(null);
          }
        },
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected 
            ? (tag.name == 'All' 
                ? Colors.blue.shade400 
                : Color(int.parse(tag.color.replaceFirst('#', '0xFF'))))
            : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        showCheckmark: false,
        selectedColor: tag.name == 'All' 
            ? Colors.blue.shade100 
            : Color(int.parse(tag.color.replaceFirst('#', '0xFF'))).withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected
              ? (tag.name == 'All' 
                  ? Colors.blue.shade700 
                  : Color(int.parse(tag.color.replaceFirst('#', '0xFF'))))
              : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: isSelected ? 2 : 0,
        shadowColor: isSelected 
          ? (tag.name == 'All' 
              ? Colors.blue.withOpacity(0.3)
              : Color(int.parse(tag.color.replaceFirst('#', '0xFF'))).withOpacity(0.3))
          : Colors.transparent,
      ),
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _showAddPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final newTagController = TextEditingController();
    String? selectedTag;
    bool isCreatingNewTag = false;
    XFile? selectedImageXFile;  // Store XFile instead of File for web compatibility
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      print('🖼️ Image selected: ${image.name}, size: ${await image.length()} bytes');
                      setDialogState(() {
                        selectedImageXFile = image;  // Store XFile directly
                      });
                      print('🖼️ selectedImageXFile set to: ${selectedImageXFile?.path}');
                    } else {
                      print('❌ No image selected');
                    }
                  },
                  icon: Icon(selectedImageXFile != null ? Icons.check_circle : Icons.add_photo_alternate_outlined),
                  label: Text(selectedImageXFile != null ? 'Image Selected' : 'Add Image'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: selectedImageXFile != null ? Colors.green : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Tag Selection Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Tag (Optional)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              isCreatingNewTag = !isCreatingNewTag;
                              if (isCreatingNewTag) {
                                selectedTag = null;
                              } else {
                                newTagController.clear();
                              }
                            });
                          },
                          child: Text(
                            isCreatingNewTag ? 'Select Existing' : 'Create New',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isCreatingNewTag)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: selectedTag,
                        hint: const Text('Choose a tag...'),
                        items: _tags
                            .where((tag) => tag.name != 'All')
                            .map(
                              (tag) => DropdownMenuItem<String>(
                                value: tag.name,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(tag.name),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedTag = value;
                          });
                        },
                      )
                    else
                      TextField(
                        controller: newTagController,
                        decoration: const InputDecoration(
                          labelText: 'New Tag Name',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        textCapitalization: TextCapitalization.words,
                        maxLength: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || 
                    contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in title and content'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  print('📝 Creating post...');
                  print('📝 Title: ${titleController.text.trim()}');
                  print('📝 Content: ${contentController.text.trim()}');
                  print('📝 Selected image: ${selectedImageXFile?.name}');
                  
                  // Determine which tag to use
                  final tagToUse = isCreatingNewTag 
                    ? newTagController.text.trim().isEmpty 
                      ? null 
                      : newTagController.text.trim()
                    : selectedTag;
                  
                  print('📝 Selected tag: $tagToUse');
                  
                  // Create the post with tag name
                  final result = await SocialService.createPost(
                    title: titleController.text.trim(),
                    content: contentController.text.trim(),
                    tagName: tagToUse,  // Pass tag name instead of ID
                    imageFile: selectedImageXFile,  // Pass XFile directly
                  );
                  
                  print('📝 Post creation result: $result');
                  
                  Navigator.pop(context);
                  
                  if (result != null) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tagToUse != null 
                          ? 'Post created successfully with tag "$tagToUse"!' 
                          : 'Post created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    // Refresh posts and tags to include new data
                    if (mounted) {
                      setState(() {
                        _selectedTag = null; // Show all posts to ensure new post is visible
                      });
                      await _loadData(); // Reload both posts and tags
                    }
                  } else {
                    throw Exception('Post creation returned null');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create post: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // Top greeting & profile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_currentUser != null)
                    Text(
                      _currentUser!['name'] ?? 'User',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: _currentUser?['profile_image'] != null 
                      ? NetworkImage(_currentUser!['profile_image']) 
                      : null,
                  child: _currentUser?['profile_image'] == null
                      ? Icon(
                          Icons.person, 
                          color: Colors.blue[700],
                          size: 28,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        // Feature Icons Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Access',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 95,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    FeatureIcon(
                      label: 'Resource',
                      icon: Icons.library_books,
                      color: Colors.blue.shade600,
                      onTap: () => _navigateToPage(const StudyMaterialsHome()),
                    ),
                    const SizedBox(width: 20),
                    FeatureIcon(
                      label: 'Map',
                      icon: Icons.map,
                      color: Colors.teal.shade600,
                      onTap: () => _navigateToPage(const InstitutionalMapPage()),
                    ),
                    const SizedBox(width: 20),
                    FeatureIcon(
                      label: 'Messages',
                      icon: Icons.message_rounded,
                      color: Colors.green.shade600,
                      onTap: () => _navigateToPage(const MessagesPage()),
                    ),
                    const SizedBox(width: 20),
                    FeatureIcon(
                      label: 'Emergency',
                      icon: Icons.emergency,
                      color: Colors.red.shade600,
                      onTap: () => _navigateToPage(const BloodBankHomePage()),
                    ),
                    const SizedBox(width: 20),
                    FeatureIcon(
                      label: 'Tuition',
                      icon: Icons.school_rounded,
                      color: Colors.orange.shade600,
                      onTap: () => _navigateToPage(const TuitionPage()),
                    ),
                    const SizedBox(width: 20),
                    FeatureIcon(
                      label: 'NetBot',
                      icon: Icons.smart_toy_rounded,
                      color: Colors.purple.shade600,
                      onTap: () => _navigateToPage(const ChatbotPage()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Tags Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Tags',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (_selectedTag != null)
                    TextButton(
                      onPressed: () => _onTagSelected(null),
                      child: const Text(
                        'Clear Filter',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Responsive tags with wrap for small screens
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    // Mobile view - use Wrap for multiple rows
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) => _buildTagChip(tag)).toList(),
                    );
                  } else {
                    // Desktop/tablet view - use horizontal scroll
                    return SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tags.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildTagChip(_tags[index]),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Divider
        Container(height: 8, color: Colors.grey.shade50),
        // Blog Posts Section
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTag == null 
                              ? 'All Posts' 
                              : 'Posts in $_selectedTag',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          if (_selectedTag != null)
                            Text(
                              'Filtered by tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _showAddPostDialog,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshPosts,
                          child: _posts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _selectedTag == null 
                                          ? Icons.post_add_outlined 
                                          : Icons.filter_list_off,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _selectedTag == null 
                                          ? 'No posts available yet.\nBe the first to share something!' 
                                          : 'No posts found for "$_selectedTag".\nTry selecting a different tag or create a new post.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (_selectedTag != null)
                                        TextButton(
                                          onPressed: () => _onTagSelected(null),
                                          child: const Text(
                                            'View All Posts',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _posts.length,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemBuilder: (context, index) {
                                    final post = _posts[index];
                                    return SocialPostCard(
                                      post: post,
                                      onLikeChanged: () {
                                        // Just refresh posts when likes change
                                        _refreshPosts();
                                      },
                                      onCommentAdded: () {
                                        // Just refresh posts when comments are added  
                                        _refreshPosts();
                                      },
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusNet'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                await _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildDashboard(),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Clear the token
        await AuthService.logout();
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to login page and clear all previous routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
