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
  String description = '';
  String location = '';
  String contactInfo = '';
  bool isTutor = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isTutor ? Icons.school : Icons.person_search,
            color: Colors.blue[800],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isTutor ? 'Offer Tutoring' : 'Request Tutor',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Radio buttons for type selection
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
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
                      const Expanded(child: Text("I want to teach (Tutor)")),
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
                      const Expanded(child: Text("I need a tutor (Student)")),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: isTutor ? 'Subject/Course you teach' : 'Subject/Course needed',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.book),
              ),
              onChanged: (value) => description = value,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Location (area, city)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              onChanged: (value) => location = value,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Contact (phone/email)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.contact_phone),
              ),
              onChanged: (value) => contactInfo = value,
            ),
          ],
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
          ),
          child: const Text('POST'),
          onPressed: () {
            if (description.isNotEmpty && location.isNotEmpty && contactInfo.isNotEmpty) {
              // TODO: In a real app, you would save this to a database
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
          location: 'Online (Zoom)',
          note: 'The student is not from any BD University.',
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
          location: 'Uttara',
          note: 'Wants to sit for AS in January, 2024.',
        ),
        TutorCard(
          name: 'JANNATUL FERDOUS',
          subject: 'English Grammar & ENG 312 (Syntax)',
          location: 'Bonosree',
          note: 'Online teaching is preferable.',
        ),
      ],
    );
  }
}

class TutorCard extends StatelessWidget {
  final String name;
  final String subject;
  final String location;
  final String note;

  const TutorCard({
    super.key,
    required this.name,
    required this.subject,
    required this.location,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFDECEC),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subject),
            const SizedBox(height: 6),
            Text(location, style: TextStyle(color: Colors.red[800])),
            const SizedBox(height: 4),
            Text(note, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
