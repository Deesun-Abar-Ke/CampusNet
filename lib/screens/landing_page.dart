import 'package:flutter/material.dart';
import 'blood_bank/blood_bank_home_page.dart';
import 'tuition_page.dart';
import 'chatbot_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'study_materials/study_materials_home.dart';
import 'notifications.dart';
import '_feature_icon.dart';
import '_club_post_card.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? _selectedTag;

  final List<String> _tags = [
    'All',
    'Campus Life',
    'Technology',
    'Career',
    'Sports',
    'Events',
    'Academics',
  ];

  // Sample club posts data
  final List<Map<String, dynamic>> _clubPosts = [
    {
      'clubName': 'Programming Club',
      'timeAgo': '2 hours ago',
      'content':
          'Join us for the upcoming Hackathon! Great prizes to be won. Register now to showcase your coding skills and innovation.',
      'avatarUrl': 'assets/computer_club.jpeg',
      'tag': 'Technology',
    },
    {
      'clubName': 'Photography Club',
      'timeAgo': '5 hours ago',
      'content':
          'Photography exhibition this weekend! Come see the amazing captures by our talented members.',
      'imageUrl': 'assets/exhibition.jpeg',
      'avatarUrl': 'assets/photography_club.png',
      'tag': 'Events',
    },
    {
      'clubName': 'Sports Club',
      'timeAgo': '3 hours ago',
      'content':
          'Annual Inter-Department Cricket Tournament starting next week! Register your department team by Friday.',
      'avatarUrl': 'assets/profile.png',
      'tag': 'Sports',
    },
    {
      'clubName': 'Career Development Society',
      'timeAgo': '1 day ago',
      'content':
          'Resume Building Workshop with industry experts this Wednesday. Learn how to craft the perfect CV for your dream job!',
      'avatarUrl': 'assets/profile.png',
      'tag': 'Career',
    },
    {
      'clubName': 'Research Club',
      'timeAgo': '6 hours ago',
      'content':
          'New research paper published by our members in IEEE! Join us for a discussion session on AI Ethics.',
      'avatarUrl': 'assets/computer_club.jpeg',
      'tag': 'Academics',
    },
    {
      'clubName': 'Debating Club',
      'timeAgo': '1 day ago',
      'content':
          'Inter-university debate competition registration is now open. Form your team of three and register before July 30th.',
      'avatarUrl': 'assets/debate_club.png',
      'tag': 'Campus Life',
    },
    {
      'clubName': 'Cultural Club',
      'timeAgo': '4 hours ago',
      'content':
          'Annual Cultural Festival "Rhythm 2025" preparations are in full swing! Showcase your talents in music, dance, and drama.',
      'avatarUrl': 'assets/profile.png',
      'tag': 'Events',
    },
    {
      'clubName': 'Innovation Hub',
      'timeAgo': '2 days ago',
      'content':
          'Startup Weekend coming soon! Turn your ideas into reality with mentorship from successful entrepreneurs.',
      'avatarUrl': 'assets/computer_club.jpeg',
      'tag': 'Technology',
    },
    {
      'clubName': 'Environmental Club',
      'timeAgo': '1 hour ago',
      'content':
          'Join our Campus Clean-Up Drive this Saturday! Together we can make our campus greener and cleaner!',
      'avatarUrl': 'assets/profile.png',
      'tag': 'Campus Life',
    },
    {
      'clubName': 'Mathematics Society',
      'timeAgo': '8 hours ago',
      'content':
          'Math Olympiad registration opens tomorrow! Test your problem-solving skills and win exciting prizes.',
      'avatarUrl': 'assets/profile.png',
      'tag': 'Academics',
    },
  ];

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _showAddPostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement image picker
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Tag',
                  border: OutlineInputBorder(),
                ),
                items: _tags
                    .map(
                      (tag) => DropdownMenuItem(
                        value: tag == 'All' ? null : tag,
                        child: Text(tag),
                      ),
                    )
                    .toList(),
                onChanged: (value) {},
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
            onPressed: () {
              // TODO: Implement post creation
              Navigator.pop(context);
            },
            child: const Text('Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
              const Text(
                ' Welcome! ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
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
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('profile.png'),
                    ),
                  ),
                ],
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
              const Text(
                'Popular Tags',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tags.length,
                  itemBuilder: (context, index) {
                    final tag = _tags[index];
                    final isSelected =
                        tag == _selectedTag ||
                        (tag == 'All' && _selectedTag == null);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(tag),
                        onSelected: (selected) {
                          setState(() {
                            _selectedTag = selected
                                ? (tag == 'All' ? null : tag)
                                : null;
                          });
                        },
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade200),
                        showCheckmark: false,
                        selectedColor: Colors.blue.shade100,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                ),
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
                      const Text(
                        'Blog Posts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
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
                  child: ListView.builder(
                    itemCount: _clubPosts.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final post = _clubPosts[index];
                      if (_selectedTag != null && post['tag'] != _selectedTag) {
                        return const SizedBox.shrink();
                      }
                      return ClubPostCard(
                        clubName: post['clubName'],
                        timeAgo: post['timeAgo'],
                        content: post['content'],
                        imageUrl: post['imageUrl'],
                        avatarUrl: post['avatarUrl'],
                        tag: post['tag'],
                      );
                    },
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
      ),
      body: _buildDashboard(),
    );
  }
}
