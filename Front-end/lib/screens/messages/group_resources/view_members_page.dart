// lib/screens/messages/group_resources/view_members_page.dart
import 'package:flutter/material.dart';
import '../../../services/message_service.dart';
import '../chat_screen.dart';

class ViewMembersPage extends StatefulWidget {
  final String groupName;
  final int? conversationId;

  const ViewMembersPage({
    Key? key,
    required this.groupName,
    this.conversationId,
  }) : super(key: key);

  @override
  State<ViewMembersPage> createState() => _ViewMembersPageState();
}

class _ViewMembersPageState extends State<ViewMembersPage> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  
  List<GroupMember> _allMembers = [];
  List<GroupMember> _filteredMembers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _sortBy = 'name'; // name, role, join_date

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (widget.conversationId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid conversation ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _messageService.getConversationParticipants(widget.conversationId!);
      
      if (result['success']) {
        final participants = (result['participants'] as List)
            .map((participant) => GroupMember.fromJson(participant))
            .toList();

        setState(() {
          _allMembers = participants;
          _filteredMembers = participants;
          _sortMembers();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load members';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading members: $e';
        _isLoading = false;
      });
    }
  }

  void _filterMembers() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredMembers = List.from(_allMembers);
      } else {
        final searchTerm = _searchController.text.toLowerCase();
        _filteredMembers = _allMembers
            .where((member) =>
                member.name.toLowerCase().contains(searchTerm) ||
                member.email.toLowerCase().contains(searchTerm) ||
                member.role.displayName.toLowerCase().contains(searchTerm))
            .toList();
      }
      _sortMembers();
    });
  }

  void _sortMembers() {
    switch (_sortBy) {
      case 'name':
        _filteredMembers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'role':
        _filteredMembers.sort((a, b) => a.role.index.compareTo(b.role.index));
        break;
      case 'join_date':
        _filteredMembers.sort((a, b) => b.joinDate.compareTo(a.joinDate));
        break;
    }
  }

  void _changeSortBy(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _sortMembers();
    });
  }

  Future<void> _removeMember(GroupMember member) async {
    if (widget.conversationId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.name} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _messageService.removeParticipant(
          widget.conversationId!,
          member.id,
        );

        if (result['success']) {
          await _loadMembers(); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} has been removed from the group'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorSnackBar(result['message'] ?? 'Failed to remove member');
        }
      } catch (e) {
        _showErrorSnackBar('Error removing member: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
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
            const SizedBox(height: 8),
            _buildDetailRow('Joined', _formatDate(member.joinDate)),
            const SizedBox(height: 8),
            _buildDetailRow('Status', member.isOnline ? 'Online' : 'Offline'),
            if (!member.isOnline) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Last seen', _formatLastSeen(member.lastSeen)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    contactName: member.name,
                    avatar: member.name[0].toUpperCase(),
                    isOnline: member.isOnline,
                  ),
                ),
              );
            },
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
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
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.blue),
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
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.green),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                _showMemberDetails(member);
              },
            ),
            if (member.role != MemberRole.admin)
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text('Remove from Group'),
                onTap: () {
                  Navigator.pop(context);
                  _removeMember(member);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              widget.groupName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
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
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/add_member');
              if (result == true) {
                _loadMembers(); // Refresh the list if members were added
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMembers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMembers,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Column(
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

                    // Members count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.group, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            '${_filteredMembers.length} member${_filteredMembers.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(filtered from ${_allMembers.length})',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ],
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
                                    _searchController.text.isNotEmpty
                                        ? 'No members found matching your search'
                                        : 'No members in this group',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchController.text.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterMembers();
                                      },
                                      child: const Text('Clear search'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMembers,
                              child: ListView.builder(
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
                    ),
                  ],
                ),
    );
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
      margin: const EdgeInsets.symmetric(vertical: 4),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: member.role.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: member.role.color.withOpacity(0.3)),
              ),
              child: Text(
                member.role.displayName,
                style: TextStyle(
                  color: member.role.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email),
            const SizedBox(height: 4),
            Text(
              member.isOnline 
                  ? 'Online now' 
                  : 'Last seen ${_formatLastSeen(member.lastSeen)}',
              style: TextStyle(
                color: member.isOnline ? Colors.green : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMoreOptions,
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
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
  final int id;
  final String name;
  final String email;
  final MemberRole role;
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

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      joinDate: DateTime.tryParse(json['joined_at'] ?? '') ?? DateTime.now(),
      isOnline: json['is_online'] ?? false,
      lastSeen: DateTime.tryParse(json['last_seen'] ?? '') ?? DateTime.now(),
    );
  }

  static MemberRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return MemberRole.admin;
      case 'moderator':
        return MemberRole.moderator;
      default:
        return MemberRole.member;
    }
  }
}
