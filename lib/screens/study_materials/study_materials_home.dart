// lib/screens/study_materials/study_materials_home.dart
import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'department_courses_page.dart';

class StudyMaterialsHome extends StatefulWidget {
  const StudyMaterialsHome({super.key});

  @override
  State<StudyMaterialsHome> createState() => _StudyMaterialsHomeState();
}

class _StudyMaterialsHomeState extends State<StudyMaterialsHome> {
  String searchQuery = '';
  List<String> allCourses = [];

  @override
  void initState() {
    super.initState();
    // Populate allCourses from departments
    for (var dept in departments) {
      allCourses.addAll(dept['courses'] as List<String>);
    }
  }

  final List<Map<String, dynamic>> departments = const [
    // Faculty of Civil Engineering (FCE)
    {
      'name': 'Civil Engineering (CE)',
      'faculty': 'Faculty of Civil Engineering',
      'icon': Icons.construction,
      'color': Colors.orange,
      'courses': [
        'Structural Engineering',
        'Geotechnical Engineering',
        'Transportation Engineering',
        'Construction Management',
        'Concrete Technology',
        'Steel Structures',
      ],
    },
    {
      'name': 'Environmental, Water Resources & Coastal Engineering (EWCE)',
      'faculty': 'Faculty of Civil Engineering',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'courses': [
        'Environmental Engineering',
        'Water Resources Engineering',
        'Coastal Engineering',
        'Hydraulics',
        'Water Treatment',
        'Environmental Impact Assessment',
      ],
    },
    {
      'name': 'Architecture',
      'faculty': 'Faculty of Civil Engineering',
      'icon': Icons.architecture,
      'color': Colors.purple,
      'courses': [
        'Architectural Design',
        'Building Technology',
        'History of Architecture',
        'Urban Planning',
        'Environmental Design',
        'Building Information Modeling',
      ],
    },
    {
      'name': 'Petroleum & Mining Engineering (PME)',
      'faculty': 'Faculty of Civil Engineering',
      'icon': Icons.oil_barrel,
      'color': Colors.brown,
      'courses': [
        'Petroleum Engineering',
        'Mining Engineering',
        'Reservoir Engineering',
        'Drilling Technology',
        'Production Engineering',
        'Mineral Processing',
      ],
    },
    // Faculty of Electrical & Computer Engineering (FECE)
    {
      'name': 'Computer Science & Engineering (CSE)',
      'faculty': 'Faculty of Electrical & Computer Engineering',
      'icon': Icons.computer,
      'color': Colors.indigo,
      'courses': [
        'Artificial Intelligence',
        'Machine Learning',
        'Data Structures & Algorithms',
        'Database Systems',
        'Computer Networks',
        'Software Engineering',
        'Operating Systems',
        'Computer Graphics',
      ],
    },
    {
      'name': 'Electrical, Electronic & Communication Engineering (EECE)',
      'faculty': 'Faculty of Electrical & Computer Engineering',
      'icon': Icons.electrical_services,
      'color': Colors.amber,
      'courses': [
        'Digital Signal Processing',
        'Power Systems',
        'Electronics',
        'Communication Systems',
        'Control Systems',
        'Microprocessors',
        'VLSI Design',
      ],
    },
    // Faculty of Mechanical Engineering (FME)
    {
      'name': 'Mechanical Engineering (ME)',
      'faculty': 'Faculty of Mechanical Engineering',
      'icon': Icons.precision_manufacturing,
      'color': Colors.red,
      'courses': [
        'Thermodynamics',
        'Fluid Mechanics',
        'Machine Design',
        'Manufacturing Processes',
        'Heat Transfer',
        'Mechanical Vibrations',
        'CAD/CAM',
      ],
    },
    {
      'name': 'Aeronautical Engineering (AE)',
      'faculty': 'Faculty of Mechanical Engineering',
      'icon': Icons.flight,
      'color': Colors.lightBlue,
      'courses': [
        'Aerodynamics',
        'Aircraft Structures',
        'Propulsion Systems',
        'Flight Mechanics',
        'Aircraft Design',
        'Avionics',
      ],
    },
    {
      'name': 'Naval Architecture & Marine Engineering (NAME)',
      'faculty': 'Faculty of Mechanical Engineering',
      'icon': Icons.directions_boat,
      'color': Colors.teal,
      'courses': [
        'Ship Design',
        'Marine Engineering',
        'Naval Architecture',
        'Ship Hydrostatics',
        'Marine Propulsion',
        'Ocean Engineering',
      ],
    },
    {
      'name': 'Industrial & Production Engineering (IPE)',
      'faculty': 'Faculty of Mechanical Engineering',
      'icon': Icons.factory,
      'color': Colors.deepOrange,
      'courses': [
        'Production Planning',
        'Quality Control',
        'Operations Research',
        'Industrial Management',
        'Supply Chain Management',
        'Ergonomics',
      ],
    },
    // Other Departments
    {
      'name': 'Nuclear Science & Engineering (NSE)',
      'faculty': 'Specialized Department',
      'icon': Icons.science,
      'color': Colors.green,
      'courses': [
        'Nuclear Physics',
        'Reactor Engineering',
        'Nuclear Safety',
        'Radiation Protection',
        'Nuclear Materials',
        'Medical Physics',
      ],
    },
    {
      'name': 'Biomedical Engineering (BME)',
      'faculty': 'Specialized Department',
      'icon': Icons.biotech,
      'color': Colors.pink,
      'courses': [
        'Medical Instrumentation',
        'Biomechanics',
        'Biomedical Signal Processing',
        'Medical Imaging',
        'Tissue Engineering',
        'Rehabilitation Engineering',
      ],
    },
    {
      'name': 'Science & Humanities (SH)',
      'faculty': 'General Department',
      'icon': Icons.school,
      'color': Colors.cyan,
      'courses': [
        'Mathematics',
        'Physics',
        'Chemistry',
        'English',
        'Economics',
        'Philosophy',
        'Psychology',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = departments
        .where(
          (dept) => dept['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('Study Materials'), 
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search departments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final department = filtered[index];
                final courses = department['courses'] as List<String>;
                final color = department['color'] as Color;
                
                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DepartmentCoursesPage(
                            departmentName: department['name'],
                            courses: courses,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              department['icon'] as IconData,
                              size: 32,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            department['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
