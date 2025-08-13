// lib/screens/messages/group_resources/view_members_page.dart
import 'package:flutter/material.dart';
import '../chat_screen.dart';

class ViewMembersPage extends StatefulWidget {
  final String groupName;

  const ViewMembersPage({
    Key? key,
    required this.groupName,
  }) : super(key: key);

  @override
  State<ViewMembersPage> createState() => _ViewMembersPageState();
}

class _ViewMembersPageState extends State<ViewMembersPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Sample group members data
  final List<GroupMember> _allMembers = [
    GroupMember(
      id: '1',
      name: 'Prof. Rahman',
      email: 'prof.rahman@university.edu',
      role: MemberRole.admin,
      joinDate: DateTime.now().subtract(const Duration(days: 30)),
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    GroupMember(
      id: '2',
      name: 'Ahmed Hassan',
      email: 'ahmed.hassan@student.edu',
      role: MemberRole.moderator,
      joinDate: DateTime.now().subtract(const Duration(days: 25)),
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GroupMember(
      id: '3',
      name: 'Sarah Khan',
      email: 'sarah.khan@student.edu',
      role: MemberRole.member,
      joinDate: DateTime.now().subtract(const Duration(days: 20)),
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
    GroupMember(
      id: '4',
      name: 'Nadia Rahman',
      email: 'nadia.rahman@student.edu',
      role: MemberRole.member,
      joinDate: DateTime.now().subtract(const Duration(days: 18)),
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    GroupMember(
      id: '5',
      name: 'Karim Uddin',
      email: 'karim.uddin@student.edu',
      role: MemberRole.member,
      joinDate: DateTime.now().subtract(const Duration(days: 15)),
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    GroupMember(
      id: '6',
      name: 'Fatima Ali',
      email: 'fatima.ali@student.edu',
      role: MemberRole.member,
      joinDate: DateTime.now().subtract(const Duration(days: 12)),
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
    ),
    GroupMember(
      id: '7',
      name: 'Omar Sheikh',
      email: 'omar.sheikh@student.edu',
      role: MemberRole.member,
      joinDate: DateTime.now().subtract(const Duration(days: 10)),
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    GroupMember(
      id: '8',
      name: 'Zara Ahmed',
      email: 'zara.ahmed@student.edu',
      role: MemberRole.member,
      joinDate: DateTime.now().subtract(const Duration(days: 8)),
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  List<GroupMember> _filteredMembers = [];
  String _sortBy = 'name'; // name, role, join_date

  @override
  void initState() {
    super.initState();
    _filteredMembers = List.from(_allMembers);
    _sortMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMembers() {
    setState(() {
      _filteredMembers = _allMembers
          .where((member) =>
              member.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              member.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              member.role.toString().toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
      _sortMembers();
    });
  }

  void _sortMembers() {
    _filteredMembers.sort((a, b) {
      switch (_sortBy) {
        case 'role':
          return a.role.index.compareTo(b.role.index);
        case 'join_date':
          return b.joinDate.compareTo(a.joinDate);
        case 'name':
        default:
          return a.name.compareTo(b.name);
      }
    });
  }

  void _changeSortBy(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _sortMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _allMembers.where((m) => m.isOnline).length;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_allMembers.length} members • $onlineCount online',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'role',
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: _sortBy == 'role' ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Role'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'join_date',
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _sortBy == 'join_date' ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Join Date'),
                  ],
                ),
              ),
            ],
            onSelected: _changeSortBy,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.pushNamed(context, '/add_member');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Members List
          Expanded(
            child: _filteredMembers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No members found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return MemberTile(
                        member: member,
                        onTap: () => _showMemberDetails(member),
                        onMoreOptions: () => _showMemberOptions(member),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showMemberDetails(GroupMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal[100],
              child: Text(
                member.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.teal[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    member.role.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: member.role.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', member.email),
            _buildDetailRow('Role', member.role.displayName),
            _buildDetailRow('Joined', _formatJoinDate(member.joinDate)),
            _buildDetailRow('Status', member.isOnline ? 'Online' : 'Last seen ${_formatLastSeen(member.lastSeen)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (member.role != MemberRole.admin)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showMemberOptions(member);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Manage'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(GroupMember member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal[100],
                child: Text(
                  member.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(member.name),
              subtitle: Text(member.role.displayName),
            ),
            const Divider(),
            if (member.role != MemberRole.admin) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                title: const Text('Change Role'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeRoleDialog(member);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('Send Message'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        contactName: member.name,
                        avatar: member.name[0].toUpperCase(),
                        isOnline: member.isOnline,
                      ),
                      settings: const RouteSettings(name: '/chat'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text('Remove from Group'),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveMemberDialog(member);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: const Text('Group Administrator'),
                subtitle: const Text('Cannot be removed or modified'),
                enabled: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(GroupMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${member.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MemberRole.values
              .where((role) => role != MemberRole.admin)
              .map((role) => RadioListTile<MemberRole>(
                    title: Text(role.displayName),
                    subtitle: Text(role.description),
                    value: role,
                    groupValue: member.role,
                    onChanged: (value) {
                      Navigator.pop(context);
                      if (value != null) {
                        _changeRole(member, value);
                      }
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(GroupMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.name} from this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(member);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _changeRole(GroupMember member, MemberRole newRole) {
    setState(() {
      member.role = newRole;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.name} is now a ${newRole.displayName}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeMember(GroupMember member) {
    setState(() {
      _allMembers.remove(member);
      _filteredMembers.remove(member);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.name} removed from group'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class MemberTile extends StatelessWidget {
  final GroupMember member;
  final VoidCallback onTap;
  final VoidCallback onMoreOptions;

  const MemberTile({
    Key? key,
    required this.member,
    required this.onTap,
    required this.onMoreOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal[100],
              child: Text(
                member.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.teal[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (member.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: member.role.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: member.role.color.withOpacity(0.3)),
              ),
              child: Text(
                member.role.displayName,
                style: TextStyle(
                  fontSize: 10,
                  color: member.role.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email),
            Text(
              member.isOnline
                  ? 'Online'
                  : 'Last seen ${_formatLastSeen(member.lastSeen)}',
              style: TextStyle(
                fontSize: 12,
                color: member.isOnline ? Colors.green : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: member.role != MemberRole.admin
            ? IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: onMoreOptions,
              )
            : Icon(Icons.shield, color: member.role.color),
        onTap: onTap,
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

enum MemberRole {
  admin,
  moderator,
  member,
}

extension MemberRoleExtension on MemberRole {
  String get displayName {
    switch (this) {
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.moderator:
        return 'Moderator';
      case MemberRole.member:
        return 'Member';
    }
  }

  String get description {
    switch (this) {
      case MemberRole.admin:
        return 'Full access to group settings and management';
      case MemberRole.moderator:
        return 'Can manage members and moderate content';
      case MemberRole.member:
        return 'Can participate in group discussions';
    }
  }

  Color get color {
    switch (this) {
      case MemberRole.admin:
        return Colors.red;
      case MemberRole.moderator:
        return Colors.orange;
      case MemberRole.member:
        return Colors.blue;
    }
  }
}

class GroupMember {
  final String id;
  final String name;
  final String email;
  MemberRole role;
  final DateTime joinDate;
  final bool isOnline;
  final DateTime lastSeen;

  GroupMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinDate,
    required this.isOnline,
    required this.lastSeen,
  });
}
