import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import 'floor_detail_page.dart';

class TowerDetailPage extends StatefulWidget {
  final String towerName;
  final Map<String, List<String>> towerData;

  const TowerDetailPage({
    super.key,
    required this.towerName,
    required this.towerData,
  });

  @override
  State<TowerDetailPage> createState() => _TowerDetailPageState();
}

class _TowerDetailPageState extends State<TowerDetailPage> {
  List<String> _getSortedFloors() {
    final floors = widget.towerData.keys.toList();
    
    // Custom sort to handle basement floors and numeric floors properly
    floors.sort((a, b) {
      // Handle basement floors
      if (a.startsWith('Basement') && b.startsWith('Basement')) {
        final aNum = int.tryParse(a.split('-').last) ?? 0;
        final bNum = int.tryParse(b.split('-').last) ?? 0;
        return bNum.compareTo(aNum); // Basement-1 before Basement-2
      }
      if (a.startsWith('Basement')) return 1; // Basements go to bottom
      if (b.startsWith('Basement')) return -1;
      
      // Handle numbered floors
      final aNum = _extractFloorNumber(a);
      final bNum = _extractFloorNumber(b);
      
      return bNum.compareTo(aNum); // Higher floors first
    });
    
    return floors;
  }
  
  int _extractFloorNumber(String floorName) {
    if (floorName.contains('Ground')) return 0;
    if (floorName.contains('First')) return 1;
    if (floorName.contains('Second')) return 2;
    if (floorName.contains('Third')) return 3;
    if (floorName.contains('Fourth')) return 4;
    if (floorName.contains('Fifth')) return 5;
    if (floorName.contains('Sixth')) return 6;
    if (floorName.contains('Seventh')) return 7;
    if (floorName.contains('Eighth')) return 8;
    if (floorName.contains('Ninth')) return 9;
    if (floorName.contains('Tenth')) return 10;
    if (floorName.contains('Eleventh')) return 11;
    return 0;
  }
  
  Color _getTowerColor() {
    switch (widget.towerName) {
      case 'Tower 1':
        return Colors.blue;
      case 'Tower 2':
        return Colors.green;
      case 'Tower 3':
        return Colors.orange;
      case 'Faculty Tower 4':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getTowerIcon() {
    switch (widget.towerName) {
      case 'Tower 1':
        return Icons.looks_one;
      case 'Tower 2':
        return Icons.looks_two;
      case 'Tower 3':
        return Icons.looks_3;
      case 'Faculty Tower 4':
        return Icons.looks_4;
      default:
        return Icons.business;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedFloors = _getSortedFloors();
    final towerColor = _getTowerColor();
    final totalRooms = widget.towerData.values.fold<int>(
      0, 
      (sum, rooms) => sum + rooms.length,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CommonAppBar(
        title: Text(
          widget.towerName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        showBackButton: true,
        centerTitle: true,
        backgroundColor: towerColor,
      ),
      body: Column(
        children: [
          // Tower Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [towerColor, towerColor.withOpacity(0.8)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTowerIcon(),
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.towerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${sortedFloors.length} floors • $totalRooms rooms/labs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Floor Statistics
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  icon: Icons.layers,
                  value: sortedFloors.length.toString(),
                  label: 'Total Floors',
                  color: towerColor,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                _buildStatItem(
                  icon: Icons.room,
                  value: totalRooms.toString(),
                  label: 'Total Rooms',
                  color: towerColor,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                _buildStatItem(
                  icon: Icons.domain,
                  value: widget.towerData.values.where((rooms) => rooms.isNotEmpty).length.toString(),
                  label: 'Active Floors',
                  color: towerColor,
                ),
              ],
            ),
          ),
          
          // Floors List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a Floor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sortedFloors.length,
                      itemBuilder: (context, index) {
                        final floorName = sortedFloors[index];
                        final rooms = widget.towerData[floorName]!;
                        return _buildFloorCard(floorName, rooms, towerColor);
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
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFloorCard(String floorName, List<String> rooms, Color towerColor) {
    final roomCount = rooms.length;
    final isEmpty = rooms.isEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isEmpty ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FloorDetailPage(
                towerName: widget.towerName,
                floorName: floorName,
                rooms: rooms,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isEmpty ? Border.all(color: Colors.grey.shade300) : null,
          ),
          child: Row(
            children: [
              // Floor Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEmpty 
                      ? Colors.grey.shade200 
                      : towerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  floorName.startsWith('Basement') 
                      ? Icons.garage 
                      : floorName.contains('Ground')
                      ? Icons.layers
                      : Icons.business,
                  color: isEmpty ? Colors.grey : towerColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Floor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      floorName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEmpty ? Colors.grey : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty 
                          ? 'No rooms/labs available'
                          : '$roomCount ${roomCount == 1 ? 'room' : 'rooms'}/labs',
                      style: TextStyle(
                        fontSize: 14,
                        color: isEmpty ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow or Empty indicator
              Icon(
                isEmpty ? Icons.block : Icons.arrow_forward_ios,
                color: isEmpty ? Colors.grey : towerColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
