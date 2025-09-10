import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../services/profile_service.dart';
import '../../../services/auth_service.dart';

class EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback? onProfileUpdated;

  const EditProfileSheet({
    super.key,
    this.profileData,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileSheet> createState() => EditProfileSheetState();
}

class EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _studentIdController;
  late TextEditingController _batchController;
  late TextEditingController _departmentController;
  late TextEditingController _hometownController;
  late TextEditingController _linkedinController;
  late TextEditingController _facebookController;
  late TextEditingController _githubController;
  late TextEditingController _currentSemesterController;
  late TextEditingController _cgpaController;

  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.profileData?['name'] ?? '');
    _emailController = TextEditingController(text: widget.profileData?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.profileData?['phone'] ?? '');
    _bioController = TextEditingController(text: widget.profileData?['bio'] ?? '');
    _studentIdController = TextEditingController(text: widget.profileData?['student_id'] ?? '');
    _batchController = TextEditingController(text: widget.profileData?['batch'] ?? '');
    _departmentController = TextEditingController(text: widget.profileData?['department'] ?? '');
    _hometownController = TextEditingController(text: widget.profileData?['hometown'] ?? '');
    _linkedinController = TextEditingController(text: widget.profileData?['linkedin_url'] ?? '');
    _facebookController = TextEditingController(text: widget.profileData?['facebook_url'] ?? '');
    _githubController = TextEditingController(text: widget.profileData?['github_url'] ?? '');
    _currentSemesterController = TextEditingController(text: widget.profileData?['current_semester'] ?? '');
    _cgpaController = TextEditingController(text: widget.profileData?['cgpa']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _studentIdController.dispose();
    _batchController.dispose();
    _departmentController.dispose();
    _hometownController.dispose();
    _linkedinController.dispose();
    _facebookController.dispose();
    _githubController.dispose();
    _currentSemesterController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Prepare profile data
      final profileData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'student_id': _studentIdController.text.trim(),
        'batch': _batchController.text.trim(),
        'department': _departmentController.text.trim(),
        'hometown': _hometownController.text.trim(),
        'current_semester': _currentSemesterController.text.trim(),
        'cgpa': _cgpaController.text.trim().isNotEmpty ? double.tryParse(_cgpaController.text.trim()) : null,
        'linkedin_url': _linkedinController.text.trim(),
        'facebook_url': _facebookController.text.trim(),
        'github_url': _githubController.text.trim(),
      };

      // Remove empty fields
      profileData.removeWhere((key, value) => 
        value == null || (value is String && value.isEmpty));

      // Update profile
      final profileSuccess = await ProfileService.updateProfile(token, profileData);

      // Upload profile picture if selected
      bool pictureSuccess = true;
      if (_selectedImageBytes != null) {
        pictureSuccess = await ProfileService.uploadProfilePicture(
          token,
          _selectedImageBytes!,
          'profile_picture.jpg',
        );
      }

      if (profileSuccess && pictureSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Call the callback to refresh parent widget
        widget.onProfileUpdated?.call();
        
        Navigator.pop(context);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Profile Picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: _selectedImageBytes != null
                        ? MemoryImage(_selectedImageBytes!)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: _selectedImageBytes == null
                        ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Student ID
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Batch and Department Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _batchController,
                      decoration: const InputDecoration(
                        labelText: 'Batch',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Semester and CGPA Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currentSemesterController,
                      decoration: const InputDecoration(
                        labelText: 'Current Semester',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cgpaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'CGPA',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final cgpa = double.tryParse(value);
                          if (cgpa == null || cgpa < 0 || cgpa > 4.0) {
                            return 'Enter valid CGPA (0.0-4.0)';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Hometown
              TextFormField(
                controller: _hometownController,
                decoration: const InputDecoration(
                  labelText: 'Hometown',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Social Links Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Social Links',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // LinkedIn
              TextFormField(
                controller: _linkedinController,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Facebook
              TextFormField(
                controller: _facebookController,
                decoration: const InputDecoration(
                  labelText: 'Facebook URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.facebook),
                ),
              ),
              const SizedBox(height: 16),

              // GitHub
              TextFormField(
                controller: _githubController,
                decoration: const InputDecoration(
                  labelText: 'GitHub URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
