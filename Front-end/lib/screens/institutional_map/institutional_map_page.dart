import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'campus_data.dart';
import 'map_search_delegate.dart';
import 'tower_detail_page.dart';

class InstitutionalMapPage extends StatefulWidget {
  const InstitutionalMapPage({super.key});

  @override
  State<InstitutionalMapPage> createState() => _InstitutionalMapPageState();
}

class _InstitutionalMapPageState extends State<InstitutionalMapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CommonAppBar(
        title: const Text(
          "MIST Campus Map",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        showBackButton: true,
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Rooms',
            onPressed: () {
              showSearch(
                context: context,
                delegate: MapSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section with reduced padding
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_city,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Military Institute of Science & Technology',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Navigate through ${campusData.keys.length} towers • Find classrooms, labs & departments',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Quick Stats with reduced padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.business,
                    count: campusData.keys.length.toString(),
                    label: 'Towers',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.layers,
                    count: _getTotalFloors().toString(),
                    label: 'Floors',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.room,
                    count: _getTotalRooms().toString(),
                    label: 'Rooms',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Towers Grid - Make this flexible and responsive
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a Tower',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: campusData.keys.length,
                      itemBuilder: (context, index) {
                        final towerName = campusData.keys.elementAt(index);
                        final towerData = campusData[towerName]!;
                        return _buildTowerCard(towerName, towerData);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTowerCard(String towerName, Map<String, List<String>> towerData) {
    final floorCount = towerData.keys.length;
    final roomCount = towerData.values.fold<int>(
      0, 
      (sum, rooms) => sum + rooms.length,
    );
    
    Color towerColor;
    IconData towerIcon;
    String imagePath;
    
    switch (towerName) {
      case 'Tower 1':
        towerColor = Colors.blue;
        towerIcon = Icons.looks_one;
        imagePath = 'assets/images/towers/tower1.jpg';
        break;
      case 'Tower 2':
        towerColor = Colors.green;
        towerIcon = Icons.looks_two;
        imagePath = 'assets/images/towers/tower2.jpg';
        break;
      case 'Tower 3':
        towerColor = Colors.orange;
        towerIcon = Icons.looks_3;
        imagePath = 'assets/images/towers/tower3.jpg';
        break;
      case 'Faculty Tower 4':
        towerColor = Colors.purple;
        towerIcon = Icons.looks_4;
        imagePath = 'assets/images/towers/faculty_tower4.jpg';
        break;
      default:
        towerColor = Colors.grey;
        towerIcon = Icons.business;
        imagePath = '';
    }
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TowerDetailPage(
                towerName: towerName,
                towerData: towerData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Tower Image Section - optimized height
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Try to load image, fallback to gradient background with icon
                        imagePath.isNotEmpty
                            ? Image.asset(
                                imagePath,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to gradient with icon if image not found
                                  return _buildFallbackTowerImage(towerColor, towerIcon);
                                },
                              )
                            : _buildFallbackTowerImage(towerColor, towerIcon),
                        
                        // Dark overlay for better text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        
                        // Tower name overlay
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Text(
                            towerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Tower info section - make more compact
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: towerColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.layers,
                          size: 14,
                          color: towerColor,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$floorCount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: towerColor,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Floors',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.room,
                          size: 14,
                          color: towerColor,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$roomCount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: towerColor,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Rooms',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackTowerImage(Color towerColor, IconData towerIcon) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            towerColor.withOpacity(0.8),
            towerColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          towerIcon,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
  
  int _getTotalFloors() {
    return campusData.values.fold<int>(
      0, 
      (sum, tower) => sum + tower.keys.length,
    );
  }
  
  int _getTotalRooms() {
    return campusData.values.fold<int>(
      0, 
      (sum, tower) => sum + tower.values.fold<int>(
        0, 
        (floorSum, rooms) => floorSum + rooms.length,
      ),
    );
  }
}
