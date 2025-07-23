import 'package:flutter/material.dart';

class TuitionPage extends StatelessWidget {
  const TuitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          toolbarHeight: 0, // Remove all toolbar space
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button space
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'TUTORS'),
              Tab(text: 'REQUESTS'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TutorsList(),
            RequestsList(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreatePostDialog(context),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreatePostDialog(),
    );
  }
}

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  String subject = '';
  String classLevel = '';
  String location = '';
  String gender = 'Any';
  String salary = '';
  String description = '';
  bool isTutor = true;

  final List<String> genderOptions = ['Any', 'Male', 'Female'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTutor ? Icons.school : Icons.person_search,
              color: Colors.blue[800],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isTutor ? 'Offer Tutoring' : 'Request Tutor',
              style: TextStyle(
                fontSize: 20,
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selection
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: isTutor,
                          activeColor: Colors.blue[800],
                          onChanged: (value) {
                            setState(() {
                              isTutor = value!;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "I want to teach (Tutor)",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: isTutor,
                          activeColor: Colors.blue[800],
                          onChanged: (value) {
                            setState(() {
                              isTutor = value!;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "I need a tutor (Student)",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subject Field
              _buildTextField(
                label: 'Subject',
                hint: isTutor ? 'What subject do you teach?' : 'Which subject do you need help with?',
                icon: Icons.book,
                onChanged: (value) => subject = value,
              ),
              const SizedBox(height: 16),

              // Class Field
              _buildTextField(
                label: 'Class/Level',
                hint: 'e.g., Grade 10, A-Level, University',
                icon: Icons.grade,
                onChanged: (value) => classLevel = value,
              ),
              const SizedBox(height: 16),

              // Location Field
              _buildTextField(
                label: 'Location',
                hint: 'Area, city or online',
                icon: Icons.location_on,
                onChanged: (value) => location = value,
              ),
              const SizedBox(height: 16),

              // Gender Preference
              Text(
                isTutor ? 'Preferred Student Gender' : 'Preferred Tutor Gender',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: gender,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
                    items: genderOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              value == 'Male' ? Icons.male : 
                              value == 'Female' ? Icons.female : Icons.people,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        gender = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Salary Field
              _buildTextField(
                label: isTutor ? 'Expected Salary' : 'Budget',
                hint: 'e.g., ৳5000/month, ৳500/hour',
                icon: Icons.attach_money,
                onChanged: (value) => salary = value,
              ),
              const SizedBox(height: 16),

              // Description Field
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
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
                maxLines: 4,
                maxLength: 200,
                onChanged: (value) {
                  setState(() {
                    description = value;
                  });
                },
              ),
              const SizedBox(height: 8),

              // AI Refine Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement AI refinement logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI refinement coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: Icon(Icons.auto_fix_high, color: Colors.purple[600]),
                  label: Text(
                    'Refine with AI',
                    style: TextStyle(color: Colors.purple[600]),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.purple[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('POST'),
          onPressed: () {
            if (_validateForm()) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTutor 
                      ? 'Tutoring offer posted successfully!' 
                      : 'Tutor request posted successfully!',
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in all required fields'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  bool _validateForm() {
    return subject.isNotEmpty &&
           classLevel.isNotEmpty &&
           location.isNotEmpty &&
           salary.isNotEmpty &&
           description.isNotEmpty;
  }
}

class TutorsList extends StatelessWidget {
  const TutorsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        TutorCard(
          name: 'MD. Nahian Kabir Pranto',
          subject: 'Business Mathematics',
          classLevel: 'University Level',
          location: 'Online (Zoom)',
          remuneration: '৳8000/month',
          description: 'Experienced math tutor with 5+ years of teaching. Specialized in business mathematics and statistics. Can help with assignments and exam preparation.',
        ),
        TutorCard(
          name: 'Fatima Rahman',
          subject: 'Physics & Chemistry',
          classLevel: 'A-Level',
          location: 'Dhanmondi, Dhaka',
          remuneration: '৳6000/month',
          description: 'MSc in Physics from DU. Expert in A-level science subjects. Proven track record of excellent results. Patient and friendly teaching approach.',
        ),
      ],
    );
  }
}

class RequestsList extends StatelessWidget {
  const RequestsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        TutorCard(
          name: 'Samiya Hasan Anka',
          subject: 'Accounting & Business Studies',
          classLevel: 'AS Level',
          location: 'Uttara, Dhaka',
          remuneration: '৳5000/month',
          description: 'Looking for an experienced tutor for AS level preparation. Need help with practical accounting problems and business case studies. Exam in January 2024.',
        ),
        TutorCard(
          name: 'Jannatul Ferdous',
          subject: 'English Grammar & ENG 312 (Syntax)',
          classLevel: 'University (3rd Year)',
          location: 'Bonosree, Dhaka',
          remuneration: '৳4000/month',
          description: 'University student seeking help with advanced English grammar and syntax course. Prefer online sessions. Need assistance with assignments and exam preparation.',
        ),
        TutorCard(
          name: 'Rakib Ahmed',
          subject: 'Mathematics & Physics',
          classLevel: 'SSC',
          location: 'Mirpur, Dhaka',
          remuneration: '৳3500/month',
          description: 'SSC candidate needs tutor for math and physics. Weak in calculus and mechanics. Looking for patient teacher who can explain concepts clearly.',
        ),
      ],
    );
  }
}

class TutorCard extends StatelessWidget {
  final String name;
  final String subject;
  final String classLevel;
  final String location;
  final String remuneration;
  final String description;

  const TutorCard({
    super.key,
    required this.name,
    required this.subject,
    required this.classLevel,
    required this.location,
    required this.remuneration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFDECEC),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile icon, name, and message icon
            Row(
              children: [
                // Profile Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.blue[800],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Message Icon
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.message,
                      color: Colors.teal[700],
                      size: 20,
                    ),
                    onPressed: () {
                      // First show confirmation that message is being opened
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.message, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Opening chat with $name...'),
                            ],
                          ),
                          backgroundColor: Colors.teal,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'GO TO MESSAGES',
                            textColor: Colors.white,
                            onPressed: () {
                              // This creates a new route to the messages page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessagesPageWrapper(contactName: name),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    tooltip: 'Send Message',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Subject
            _buildInfoRow(
              icon: Icons.book,
              label: 'Subject',
              value: subject,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            
            // Class
            _buildInfoRow(
              icon: Icons.grade,
              label: 'Class',
              value: classLevel,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            
            // Location
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: location,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            
            // Remuneration
            _buildInfoRow(
              icon: Icons.attach_money,
              label: 'Remuneration',
              value: remuneration,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            
            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color[700],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Wrapper for Messages Page to handle contact-specific messaging
class MessagesPageWrapper extends StatelessWidget {
  final String contactName;

  const MessagesPageWrapper({super.key, required this.contactName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💬 Chat with $contactName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Contact Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[50]!, Colors.teal[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.teal[800],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contactName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tuition Contact',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.teal[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.verified, color: Colors.teal[600], size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Placeholder for chat interface
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chat Feature Coming Soon!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can start a conversation with $contactName here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chat functionality will be implemented soon!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Start Conversation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
