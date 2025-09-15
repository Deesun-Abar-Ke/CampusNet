import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'tuition_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../config.dart';

class CreateTuitionPostPage extends StatefulWidget {
  const CreateTuitionPostPage({super.key});

  @override
  State<CreateTuitionPostPage> createState() => _CreateTuitionPostPageState();
}

class _CreateTuitionPostPageState extends State<CreateTuitionPostPage> {
  String subject = '';
  String classLevel = '';
  String location = '';
  String gender = 'Any';
  String salary = '';
  String description = '';
  bool isTutor = true;
  bool isRefining = false;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.text = description;
    _descriptionController.addListener(() {
      setState(() {
        description = _descriptionController.text;
      });
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  final List<String> genderOptions = ['Any', 'Male', 'Female'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: Text(isTutor ? 'Offer Tutoring' : 'Request Tutor'),
        backgroundColor: Colors.blue[800]!,
        actions: [
          TextButton(
            onPressed: _validateForm() ? _submitPost : null,
            child: Text(
              'POST',
              style: TextStyle(
                color: _validateForm() ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selection Card
            Card(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What do you want to do?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeOption(
                            title: 'Offer Tutoring',
                            subtitle: 'I want to teach',
                            icon: Icons.school,
                            isSelected: isTutor,
                            onTap: () => setState(() => isTutor = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeOption(
                            title: 'Request Tutor',
                            subtitle: 'I need help',
                            icon: Icons.person_search,
                            isSelected: !isTutor,
                            onTap: () => setState(() => isTutor = false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            _buildTextField(
              label: 'Subject',
              hint: isTutor
                  ? 'What subject do you teach?'
                  : 'Which subject do you need help with?',
              icon: Icons.book,
              onChanged: (value) => setState(() => subject = value),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              label: 'Class/Level',
              hint: 'e.g., Grade 10, A-Level, University',
              icon: Icons.grade,
              onChanged: (value) => setState(() => classLevel = value),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              label: 'Location',
              hint: 'Area, city or online',
              icon: Icons.location_on,
              onChanged: (value) => setState(() => location = value),
            ),
            const SizedBox(height: 20),

            // Gender Preference
            _buildDropdownField(
              label: isTutor ? 'Preferred Student Gender' : 'Preferred Tutor Gender',
              value: gender,
              items: genderOptions,
              icon: Icons.people,
              onChanged: (value) => setState(() => gender = value!),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              label: isTutor ? 'Expected Salary' : 'Budget',
              hint: 'e.g., ৳5000/month, ৳500/hour',
              icon: Icons.attach_money,
              onChanged: (value) => setState(() => salary = value),
            ),
            const SizedBox(height: 20),

            // Description Field
            _buildDescriptionField(),
            const SizedBox(height: 16),

            // AI Refine Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isRefining ? null : _refineWithAI,
                icon: isRefining
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation(Colors.purple),
                        ),
                      )
                    : Icon(Icons.auto_fix_high, color: Colors.purple[600]),
                label: Text(
                  isRefining ? 'Refining...' : 'Refine with AI',
                  style: TextStyle(color: Colors.purple[600]),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.purple[600]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preview Card
            if (_validateForm()) _buildPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : Colors.blue[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.blue[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            prefixIcon: Icon(icon, color: Colors.blue[600]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
  TextField(
          decoration: InputDecoration(
            hintText: isTutor
                ? 'Describe your teaching experience, qualifications, and approach...'
                : 'Describe what help you need, your current level, and expectations...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            prefixIcon: Icon(Icons.description, color: Colors.blue[600]),
            counterText: '${description.length}/200',
          ),
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.green[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPreviewRow(Icons.book, 'Subject', subject),
            _buildPreviewRow(Icons.grade, 'Class', classLevel),
            _buildPreviewRow(Icons.location_on, 'Location', location),
            _buildPreviewRow(Icons.attach_money, 'Salary', salary),
            if (description.isNotEmpty)
              _buildPreviewRow(Icons.description, 'Description', description),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    return subject.isNotEmpty &&
        classLevel.isNotEmpty &&
        location.isNotEmpty &&
        salary.isNotEmpty &&
        description.isNotEmpty;
  }

  void _refineWithAI() {
    if (description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a description first'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() {
      isRefining = true;
    });

    final uri = Uri.parse('${Config.baseUrl}/ai/refine');
    http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': description}))
        .then((res) {
      if (res.statusCode == 200) {
        try {
          final j = jsonDecode(res.body);
          final refined = (j['refined'] ?? '').toString();
          if (refined.isNotEmpty) {
            _descriptionController.text = refined;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Description refined'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('AI returned empty result'),
              backgroundColor: Colors.orange,
            ));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to parse AI response: $e'),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        final err = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err['msg'] ?? 'AI refine failed (${res.statusCode})'),
          backgroundColor: Colors.red,
        ));
      }
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error calling AI: $e'),
        backgroundColor: Colors.red,
      ));
    }).whenComplete(() {
      if (mounted) {
        setState(() {
          isRefining = false;
        });
      }
    });
  }

  void _submitPost() {
    if (_validateForm()) {
      _postToBackend();
    }
  }

  Future<void> _postToBackend() async {
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You must be logged in to post'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final postId = DateTime.now().millisecondsSinceEpoch.toString();
    final body = {
      'post_id': postId,
      'subject': subject,
      'class': classLevel,
      'location': location,
      'renumeration': salary,
      'description': description,
      'req_type': isTutor ? 'offer' : 'request',
    };
    print(body);
    final url = Uri.parse('${Config.baseUrl}/tutions');
    try {
      final res = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode(body));

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isTutor ? 'Tutoring offer posted successfully!' : 'Tutor request posted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        // Navigate back to tuition page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TuitionPage()),
        );
      } else {
        final err = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err['msg'] ?? 'Failed to post (${res.statusCode})'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
