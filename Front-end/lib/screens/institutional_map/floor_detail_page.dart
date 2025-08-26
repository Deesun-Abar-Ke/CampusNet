import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';

class FloorDetailPage extends StatefulWidget {
  final String towerName;
  final String floorName;
  final List<String> rooms;

  const FloorDetailPage({
    super.key,
    required this.towerName,
    required this.floorName,
    required this.rooms,
  });

  @override
  State<FloorDetailPage> createState() => _FloorDetailPageState();
}

class _FloorDetailPageState extends State<FloorDetailPage> {
  String _searchQuery = '';
  
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
  
  List<String> _getFilteredRooms() {
    if (_searchQuery.isEmpty) {
      return widget.rooms;
    }
    return widget.rooms
        .where((room) => room.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }
  
  IconData _getRoomIcon(String roomName) {
    final lowerName = roomName.toLowerCase();
    
    if (lowerName.contains('lab')) return Icons.science;
    if (lowerName.contains('classroom')) return Icons.school;
    if (lowerName.contains('department') || lowerName.contains('dept')) return Icons.domain;
    if (lowerName.contains('office')) return Icons.business_center;
    if (lowerName.contains('cafeteria')) return Icons.restaurant;
    if (lowerName.contains('library')) return Icons.local_library;
    if (lowerName.contains('hall') || lowerName.contains('seminar')) return Icons.meeting_room;
    if (lowerName.contains('parking')) return Icons.local_parking;
    if (lowerName.contains('masjid') || lowerName.contains('mosque')) return Icons.place;
    if (lowerName.contains('games') || lowerName.contains('indoor')) return Icons.sports_esports;
    if (lowerName.contains('common room')) return Icons.group;
    if (lowerName.contains('server')) return Icons.dns;
    if (lowerName.contains('research')) return Icons.biotech;
    if (lowerName.contains('faculty')) return Icons.person;
    if (lowerName.contains('dean')) return Icons.admin_panel_settings;
    
    return Icons.room;
  }
  
  Color _getRoomColor(String roomName) {
    final lowerName = roomName.toLowerCase();
    final towerColor = _getTowerColor();
    
    if (lowerName.contains('lab')) return Colors.blue;
    if (lowerName.contains('classroom')) return Colors.green;
    if (lowerName.contains('department') || lowerName.contains('dept')) return Colors.purple;
    if (lowerName.contains('office')) return Colors.orange;
    if (lowerName.contains('cafeteria')) return Colors.red;
    if (lowerName.contains('library')) return Colors.brown;
    if (lowerName.contains('hall') || lowerName.contains('seminar')) return Colors.indigo;
    if (lowerName.contains('parking')) return Colors.grey;
    if (lowerName.contains('masjid') || lowerName.contains('mosque')) return Colors.green.shade800;
    if (lowerName.contains('games') || lowerName.contains('indoor')) return Colors.teal;
    if (lowerName.contains('common room')) return Colors.pink;
    if (lowerName.contains('server')) return Colors.deepPurple;
    if (lowerName.contains('research')) return Colors.cyan;
    if (lowerName.contains('faculty')) return Colors.amber;
    if (lowerName.contains('dean')) return Colors.deepOrange;
    
    return towerColor;
  }

  @override
  Widget build(BuildContext context) {
    final towerColor = _getTowerColor();
    final filteredRooms = _getFilteredRooms();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CommonAppBar(
        title: Text(
          widget.floorName,
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
          // Floor Header
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
                  Icon(
                    widget.floorName.startsWith('Basement') 
                        ? Icons.garage 
                        : widget.floorName.contains('Ground')
                        ? Icons.layers
                        : Icons.business,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.floorName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.towerName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.rooms.length} rooms/labs available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Search Bar
          if (widget.rooms.length > 5)
            Container(
              margin: const EdgeInsets.all(16),
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
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search rooms on this floor...',
                  prefixIcon: Icon(Icons.search, color: towerColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          
          // Rooms Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filteredRooms.length == widget.rooms.length
                      ? 'All Rooms (${filteredRooms.length})'
                      : 'Found ${filteredRooms.length} of ${widget.rooms.length} rooms',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Rooms List
          Expanded(
            child: filteredRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No rooms found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return _buildRoomCard(room, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomCard(String roomName, int index) {
    final roomColor = _getRoomColor(roomName);
    final roomIcon = _getRoomIcon(roomName);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showRoomDetails(roomName);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Room Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: roomColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  roomIcon,
                  color: roomColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Room Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.towerName} • ${widget.floorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Room Number Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roomColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${(index + 1).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: roomColor,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                color: roomColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showRoomDetails(String roomName) {
    final roomColor = _getRoomColor(roomName);
    final roomIcon = _getRoomIcon(roomName);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Room Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: roomColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      roomIcon,
                      color: roomColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.towerName} • ${widget.floorName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Location Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Tower', widget.towerName),
                    _buildDetailRow('Floor', widget.floorName),
                    _buildDetailRow('Room/Lab', roomName),
                    _buildDetailRow('Type', _getRoomType(roomName)),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDirections(roomName);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roomColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRoomType(String roomName) {
    final lowerName = roomName.toLowerCase();
    
    if (lowerName.contains('lab')) return 'Laboratory';
    if (lowerName.contains('classroom')) return 'Classroom';
    if (lowerName.contains('department') || lowerName.contains('dept')) return 'Department Office';
    if (lowerName.contains('office')) return 'Office';
    if (lowerName.contains('cafeteria')) return 'Dining';
    if (lowerName.contains('library')) return 'Library';
    if (lowerName.contains('hall') || lowerName.contains('seminar')) return 'Meeting Hall';
    if (lowerName.contains('parking')) return 'Parking Area';
    if (lowerName.contains('masjid') || lowerName.contains('mosque')) return 'Prayer Area';
    if (lowerName.contains('games') || lowerName.contains('indoor')) return 'Recreation';
    if (lowerName.contains('common room')) return 'Common Area';
    if (lowerName.contains('server')) return 'Technical';
    if (lowerName.contains('research')) return 'Research Facility';
    if (lowerName.contains('faculty')) return 'Faculty Area';
    if (lowerName.contains('dean')) return 'Administrative';
    
    return 'General Room';
  }
  
  void _showDirections(String roomName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Directions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To reach: $roomName'),
            const SizedBox(height: 16),
            Text(
              '1. Enter ${widget.towerName}\n'
              '2. Take elevator/stairs to ${widget.floorName}\n'
              '3. Look for room signage\n'
              '4. Ask campus staff if needed',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
