import 'package:flutter/material.dart';
import 'campus_data.dart';
import 'floor_detail_page.dart';

class MapSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search classrooms, labs, departments...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _searchRooms(query);
    
    if (results.isEmpty) {
      return Center(
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
              'No results found',
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
      );
    }
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildSearchResultCard(context, result);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      final suggestions = _getPopularSearches();
      return _buildSuggestionsView(context, suggestions);
    }
    
    final suggestions = _searchRooms(query);
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final result = suggestions[index];
        return _buildSearchResultCard(context, result);
      },
    );
  }
  
  List<SearchResult> _searchRooms(String searchQuery) {
    final results = <SearchResult>[];
    final lowerQuery = searchQuery.toLowerCase();
    
    if (lowerQuery.isEmpty) return results;
    
    campusData.forEach((towerName, floors) {
      floors.forEach((floorName, rooms) {
        for (final room in rooms) {
          if (room.toLowerCase().contains(lowerQuery)) {
            results.add(SearchResult(
              roomName: room,
              towerName: towerName,
              floorName: floorName,
              allRoomsInFloor: rooms,
            ));
          }
        }
      });
    });
    
    // Sort results by relevance (exact matches first, then partial matches)
    results.sort((a, b) {
      final aExact = a.roomName.toLowerCase().startsWith(lowerQuery);
      final bExact = b.roomName.toLowerCase().startsWith(lowerQuery);
      
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      return a.roomName.length.compareTo(b.roomName.length);
    });
    
    return results;
  }
  
  List<String> _getPopularSearches() {
    return [
      'CSE',
      'Lab',
      'Classroom',
      'Department',
      'Cafeteria',
      'Library',
      'Seminar Hall',
      'Office',
      'Masjid',
      'Parking',
      'BME',
      'ME',
      'EECE',
      'CE',
      'AE',
      'NSE',
      'NAME',
    ];
  }
  
  Widget _buildSuggestionsView(BuildContext context, List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Popular Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((suggestion) {
                  return InkWell(
                    onTap: () {
                      query = suggestion;
                      showResults(context);
                    },
                    child: Chip(
                      label: Text(suggestion),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Search Tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        _buildSearchTip(
          icon: Icons.search,
          title: 'Search by Room Type',
          description: 'Try "Lab", "Classroom", "Department"',
        ),
        _buildSearchTip(
          icon: Icons.school,
          title: 'Search by Department',
          description: 'Try "CSE", "ME", "EECE", "BME"',
        ),
        _buildSearchTip(
          icon: Icons.location_on,
          title: 'Search by Facility',
          description: 'Try "Cafeteria", "Library", "Masjid"',
        ),
      ],
    );
  }
  
  Widget _buildSearchTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(description),
    );
  }
  
  Widget _buildSearchResultCard(BuildContext context, SearchResult result) {
    final roomColor = _getRoomColor(result.roomName);
    final roomIcon = _getRoomIcon(result.roomName);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: roomColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            roomIcon,
            color: roomColor,
            size: 20,
          ),
        ),
        title: Text(
          result.roomName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text('${result.towerName} • ${result.floorName}'),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roomColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getRoomType(result.roomName),
                style: TextStyle(
                  fontSize: 11,
                  color: roomColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          close(context, result.roomName);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FloorDetailPage(
                towerName: result.towerName,
                floorName: result.floorName,
                rooms: result.allRoomsInFloor,
              ),
            ),
          );
        },
      ),
    );
  }
  
  Color _getRoomColor(String roomName) {
    final lowerName = roomName.toLowerCase();
    
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
    
    return Colors.blue;
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
  
  String _getRoomType(String roomName) {
    final lowerName = roomName.toLowerCase();
    
    if (lowerName.contains('lab')) return 'Laboratory';
    if (lowerName.contains('classroom')) return 'Classroom';
    if (lowerName.contains('department') || lowerName.contains('dept')) return 'Department';
    if (lowerName.contains('office')) return 'Office';
    if (lowerName.contains('cafeteria')) return 'Dining';
    if (lowerName.contains('library')) return 'Library';
    if (lowerName.contains('hall') || lowerName.contains('seminar')) return 'Hall';
    if (lowerName.contains('parking')) return 'Parking';
    if (lowerName.contains('masjid') || lowerName.contains('mosque')) return 'Prayer Area';
    if (lowerName.contains('games') || lowerName.contains('indoor')) return 'Recreation';
    if (lowerName.contains('common room')) return 'Common Area';
    if (lowerName.contains('server')) return 'Technical';
    if (lowerName.contains('research')) return 'Research';
    if (lowerName.contains('faculty')) return 'Faculty';
    if (lowerName.contains('dean')) return 'Administrative';
    
    return 'Room';
  }
}

class SearchResult {
  final String roomName;
  final String towerName;
  final String floorName;
  final List<String> allRoomsInFloor;

  SearchResult({
    required this.roomName,
    required this.towerName,
    required this.floorName,
    required this.allRoomsInFloor,
  });
}
