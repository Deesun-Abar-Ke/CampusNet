import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'edit_profile_sheet.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../services/profile_service.dart';
import '../../../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _skills = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    _token = await AuthService.getToken();
    if (_token == null) {
      // Handle no token case
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await ProfileService.getUserProfile(_token!);
      final achievements = await ProfileService.getAchievements(_token!);
      final skills = await ProfileService.getSkills(_token!);

      setState(() {
        _profileData = profile;
        _achievements = List<Map<String, dynamic>>.from(achievements);
        _skills = List<Map<String, dynamic>>.from(skills);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCV() async {
    if (_token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final cvBytes = await ProfileService.generateCV(_token!);
      Navigator.pop(context); // Close loading dialog

      if (cvBytes != null) {
        // Save CV to downloads
        await _saveCVToDownloads(cvBytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CV generated and saved to Downloads!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate CV. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCVToDownloads(Uint8List cvBytes) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory != null) {
        final fileName = 'CV_${_profileData?['name']?.replaceAll(' ', '_') ?? 'Profile'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(cvBytes);
      }
    } catch (e) {
      print('Error saving CV: $e');
    }
  }

  Widget _buildProfilePicture() {
    if (_profileData?['profile_picture'] != null) {
      // If profile picture exists in backend, decode and display
      final bytes = _profileData!['profile_picture'] as String;
      // You might need to decode base64 here
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, size: 50, color: Colors.white),
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[300],
        child: Text(
          (_profileData?['name'] ?? 'U').substring(0, 1).toUpperCase(),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: CommonAppBar(
          title: const Text("My Profile"),
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: CommonAppBar(
        title: const Text("My Profile"),
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Profile Picture
            _buildProfilePicture(),
            const SizedBox(height: 20),

            // Name and Role
            Text(
              _profileData?['name'] ?? 'User Name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "${_profileData?['designation'] ?? 'Student'}, ${_profileData?['department'] ?? 'Department'}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Bio Section (if exists)
            if (_profileData?['bio'] != null && _profileData!['bio'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "About Me",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _profileData!['bio'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Academic Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Academic Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_profileData?['student_id'] != null) ...[
                        _InfoRow(
                          icon: Icons.badge,
                          label: "Student ID",
                          value: _profileData!['student_id'],
                        ),
                        const Divider(),
                      ],
                      if (_profileData?['department'] != null) ...[
                        _InfoRow(
                          icon: Icons.school,
                          label: "Department",
                          value: _profileData!['department'],
                        ),
                        const Divider(),
                      ],
                      if (_profileData?['batch'] != null) ...[
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: "Batch",
                          value: _profileData!['batch'],
                        ),
                        const Divider(),
                      ],
                      if (_profileData?['current_semester'] != null) ...[
                        _InfoRow(
                          icon: Icons.bookmark,
                          label: "Current Semester",
                          value: _profileData!['current_semester'],
                        ),
                        const Divider(),
                      ],
                      if (_profileData?['cgpa'] != null) ...[
                        _InfoRow(
                          icon: Icons.grade,
                          label: "CGPA",
                          value: _profileData!['cgpa'].toString(),
                        ),
                        const Divider(),
                      ],
                      _InfoRow(
                        icon: Icons.work,
                        label: "Role",
                        value: _profileData?['designation'] ?? 'Student',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Personal Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Contact Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.email,
                        label: "Email",
                        value: _profileData?['email'] ?? 'N/A',
                      ),
                      if (_profileData?['phone'] != null) ...[
                        const Divider(),
                        _InfoRow(
                          icon: Icons.phone_android,
                          label: "Phone",
                          value: _profileData!['phone'],
                        ),
                      ],
                      if (_profileData?['date_of_birth'] != null) ...[
                        const Divider(),
                        _InfoRow(
                          icon: Icons.cake,
                          label: "Date of Birth",
                          value: _profileData!['date_of_birth'],
                        ),
                      ],
                      if (_profileData?['hometown'] != null) ...[
                        const Divider(),
                        _InfoRow(
                          icon: Icons.location_city,
                          label: "Hometown",
                          value: _profileData!['hometown'],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Achievements Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Achievements",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => _showAddAchievementDialog(),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_achievements.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No achievements added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your first achievement',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._achievements.map((achievement) => _buildAchievementCard(achievement)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Skills Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Skills",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => _showAddSkillDialog(),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_skills.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.psychology_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No skills added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your skills',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._buildSkillsByCategory(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Social Media Links (if available)
            if (_profileData?['linkedin_url'] != null || _profileData?['facebook_url'] != null || _profileData?['github_url'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Social Links",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (_profileData?['linkedin_url'] != null)
                          InkWell(
                            onTap: () async {
                              final Uri url = Uri.parse(_profileData!['linkedin_url']);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: const _InfoRow(
                              icon: Icons.link,
                              label: "LinkedIn",
                              value: "View Profile →",
                            ),
                          ),
                        if (_profileData?['linkedin_url'] != null && (_profileData?['facebook_url'] != null || _profileData?['github_url'] != null))
                          const Divider(),
                        if (_profileData?['facebook_url'] != null)
                          InkWell(
                            onTap: () async {
                              final Uri url = Uri.parse(_profileData!['facebook_url']);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: const _InfoRow(
                              icon: Icons.facebook,
                              label: "Facebook",
                              value: "View Profile →",
                            ),
                          ),
                        if (_profileData?['facebook_url'] != null && _profileData?['github_url'] != null)
                          const Divider(),
                        if (_profileData?['github_url'] != null)
                          InkWell(
                            onTap: () async {
                              final Uri url = Uri.parse(_profileData!['github_url']);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: const _InfoRow(
                              icon: Icons.code,
                              label: "GitHub",
                              value: "View Profile →",
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 196, 199, 221),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => EditProfileSheet(
                            profileData: _profileData,
                            onProfileUpdated: _loadProfileData,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Profile"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _generateCV,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Generate CV"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['title'] ?? 'Achievement',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (achievement['organization'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          achievement['organization'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.indigo[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(achievement['category']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getCategoryLabel(achievement['category']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditAchievementDialog(achievement);
                        } else if (value == 'delete') {
                          _deleteAchievement(achievement['id']);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (achievement['description'] != null && achievement['description'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                achievement['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            if (achievement['grade_or_result'] != null && achievement['grade_or_result'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.grade, size: 16, color: Colors.amber[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Grade: ${achievement['grade_or_result']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (achievement['location'] != null && achievement['location'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    achievement['location'],
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _getDateRange(achievement),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'education':
        return Colors.blue;
      case 'work':
        return Colors.green;
      case 'project':
        return Colors.purple;
      case 'award':
        return Colors.amber[700]!;
      case 'certification':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'education':
        return 'Education';
      case 'work':
        return 'Work';
      case 'project':
        return 'Project';
      case 'award':
        return 'Award';
      case 'certification':
        return 'Certification';
      default:
        return 'General';
    }
  }

  String _getDateRange(Map<String, dynamic> achievement) {
    final startDate = achievement['start_date'];
    final endDate = achievement['end_date'];
    final isCurrent = achievement['is_current'] ?? false;

    if (startDate == null) return 'Date not specified';

    final start = DateTime.tryParse(startDate)?.toString().split(' ')[0] ?? startDate;
    
    if (isCurrent) {
      return '$start - Present';
    } else if (endDate != null) {
      final end = DateTime.tryParse(endDate)?.toString().split(' ')[0] ?? endDate;
      return '$start - $end';
    } else {
      return start;
    }
  }

  List<Widget> _buildSkillsByCategory() {
    // Group skills by category
    Map<String, List<Map<String, dynamic>>> skillsByCategory = {};
    for (var skill in _skills) {
      String category = skill['category'] ?? 'technical';
      if (!skillsByCategory.containsKey(category)) {
        skillsByCategory[category] = [];
      }
      skillsByCategory[category]!.add(skill);
    }

    List<Widget> widgets = [];
    skillsByCategory.forEach((category, skills) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getSkillCategoryLabel(category),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) => _buildSkillChip(skill)).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    });
    return widgets;
  }

  String _getSkillCategoryLabel(String category) {
    switch (category) {
      case 'technical':
        return 'Technical Skills';
      case 'language':
        return 'Languages';
      case 'soft_skill':
        return 'Soft Skills';
      default:
        return 'Other Skills';
    }
  }

  Widget _buildSkillChip(Map<String, dynamic> skill) {
    final proficiency = skill['proficiency_level'] ?? 3;
    return InkWell(
      onTap: () => _showEditSkillDialog(skill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skill['name'] ?? 'Skill',
              style: const TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(5, (index) => Icon(
              Icons.star,
              size: 12,
              color: index < proficiency 
                  ? Colors.amber[600] 
                  : Colors.grey[300],
            )),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _deleteSkill(skill['id']),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAchievementDialog() {
    _showAchievementDialog();
  }

  void _showEditAchievementDialog(Map<String, dynamic> achievement) {
    _showAchievementDialog(achievement: achievement);
  }

  void _showAchievementDialog({Map<String, dynamic>? achievement}) {
    final titleController = TextEditingController(text: achievement?['title'] ?? '');
    final organizationController = TextEditingController(text: achievement?['organization'] ?? '');
    final descriptionController = TextEditingController(text: achievement?['description'] ?? '');
    final gradeController = TextEditingController(text: achievement?['grade_or_result'] ?? '');
    final locationController = TextEditingController(text: achievement?['location'] ?? '');
    String selectedCategory = achievement?['category'] ?? 'general';
    DateTime? startDate = achievement?['start_date'] != null 
        ? DateTime.tryParse(achievement!['start_date']) 
        : null;
    DateTime? endDate = achievement?['end_date'] != null 
        ? DateTime.tryParse(achievement!['end_date']) 
        : null;
    bool isCurrent = achievement?['is_current'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(achievement == null ? 'Add Achievement' : 'Edit Achievement'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'education', child: Text('Education')),
                      DropdownMenuItem(value: 'work', child: Text('Work Experience')),
                      DropdownMenuItem(value: 'project', child: Text('Project')),
                      DropdownMenuItem(value: 'award', child: Text('Award')),
                      DropdownMenuItem(value: 'certification', child: Text('Certification')),
                      DropdownMenuItem(value: 'general', child: Text('General')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value ?? 'general';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: organizationController,
                    decoration: const InputDecoration(labelText: 'Organization/Institution'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: gradeController,
                    decoration: const InputDecoration(labelText: 'Grade/Result (optional)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location (optional)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text('Start Date'),
                          subtitle: Text(startDate?.toString().split(' ')[0] ?? 'Not set'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setDialogState(() {
                                startDate = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!isCurrent)
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text('End Date'),
                            subtitle: Text(endDate?.toString().split(' ')[0] ?? 'Not set'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: startDate ?? DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setDialogState(() {
                                  endDate = date;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  CheckboxListTile(
                    title: const Text('Currently ongoing'),
                    value: isCurrent,
                    onChanged: (value) {
                      setDialogState(() {
                        isCurrent = value ?? false;
                        if (isCurrent) {
                          endDate = null;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                final data = {
                  'title': titleController.text.trim(),
                  'category': selectedCategory,
                  'organization': organizationController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'grade_or_result': gradeController.text.trim(),
                  'location': locationController.text.trim(),
                  'start_date': startDate?.toIso8601String().split('T')[0],
                  'end_date': isCurrent ? null : endDate?.toIso8601String().split('T')[0],
                  'is_current': isCurrent,
                };

                // Remove empty fields
                data.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

                bool success;
                if (achievement == null) {
                  success = await ProfileService.addAchievement(_token!, data);
                } else {
                  success = await ProfileService.updateAchievement(_token!, achievement['id'], data);
                }

                Navigator.pop(context);
                if (success) {
                  _loadProfileData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save achievement')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSkillDialog() {
    _showSkillDialog();
  }

  void _showEditSkillDialog(Map<String, dynamic> skill) {
    _showSkillDialog(skill: skill);
  }

  void _showSkillDialog({Map<String, dynamic>? skill}) {
    final nameController = TextEditingController(text: skill?['name'] ?? '');
    final categoryController = TextEditingController(text: skill?['category'] ?? 'technical');
    int proficiencyLevel = skill?['proficiency_level'] ?? 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(skill == null ? 'Add Skill' : 'Edit Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Skill Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: categoryController.text,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'technical', child: Text('Technical')),
                  DropdownMenuItem(value: 'language', child: Text('Language')),
                  DropdownMenuItem(value: 'soft_skill', child: Text('Soft Skill')),
                ],
                onChanged: (value) {
                  categoryController.text = value ?? 'technical';
                },
              ),
              const SizedBox(height: 16),
              Text('Proficiency Level: $proficiencyLevel/5'),
              Slider(
                value: proficiencyLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (value) {
                  setDialogState(() {
                    proficiencyLevel = value.round();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameController.text,
                  'category': categoryController.text,
                  'proficiency_level': proficiencyLevel,
                };

                bool success;
                if (skill == null) {
                  success = await ProfileService.addSkill(_token!, data);
                } else {
                  success = await ProfileService.updateSkill(_token!, skill['id'], data);
                }

                Navigator.pop(context);
                if (success) {
                  _loadProfileData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save skill')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSkill(int skillId) async {
    final success = await ProfileService.deleteSkill(_token!, skillId);
    if (success) {
      _loadProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete skill')),
      );
    }
  }

  Future<void> _deleteAchievement(int achievementId) async {
    final success = await ProfileService.deleteAchievement(_token!, achievementId);
    if (success) {
      _loadProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete achievement')),
      );
    }
  }
}

// Helper Widget for info rows
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: label == "LinkedIn" || label == "Facebook"
                  ? Colors.blue.shade700
                  : Colors.black87,
              decoration: label == "LinkedIn" || label == "Facebook"
                  ? TextDecoration.underline
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
