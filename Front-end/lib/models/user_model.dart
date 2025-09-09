class UserModel {
  final int id;
  final String name;
  final String email;
  final String avatar;
  final String? designation;
  final String? department;
  final int? level;
  final String? session;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.designation,
    this.department,
    this.level,
    this.session,
    this.isOnline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '👤',
      designation: json['designation'],
      department: json['department'],
      level: json['level'],
      session: json['session'],
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'designation': designation,
      'department': department,
      'level': level,
      'session': session,
      'is_online': isOnline,
    };
  }
}

class ConversationModel {
  final int id;
  final String? name;
  final String type;
  final String avatar;
  final String createdAt;
  final String updatedAt;
  final String? courseFolder;
  final int unreadCount;
  final int memberCount;
  final MessageModel? lastMessage;
  final List<ParticipantModel> participants;

  ConversationModel({
    required this.id,
    this.name,
    required this.type,
    required this.avatar,
    required this.createdAt,
    required this.updatedAt,
    this.courseFolder,
    this.unreadCount = 0,
    this.memberCount = 0,
    this.lastMessage,
    this.participants = const [],
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? 0,
      name: json['name'],
      type: json['type'] ?? 'individual',
      avatar: json['avatar'] ?? '👥',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      courseFolder: json['course_folder'],
      unreadCount: json['unread_count'] ?? 0,
      memberCount: json['member_count'] ?? 0,
      lastMessage: json['last_message'] != null 
          ? MessageModel.fromJson(json['last_message'])
          : null,
      participants: (json['participants'] as List?)
          ?.map((p) => ParticipantModel.fromJson(p))
          .toList() ?? [],
    );
  }
}

class MessageModel {
  final int id;
  final String content;
  final String sentAt;
  final String senderName;
  final String messageType;
  final bool isMe;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;

  MessageModel({
    required this.id,
    required this.content,
    required this.sentAt,
    required this.senderName,
    required this.messageType,
    this.isMe = false,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      sentAt: json['sent_at'] ?? '',
      senderName: json['sender_name'] ?? 'Unknown',
      messageType: json['message_type'] ?? 'text',
      isMe: json['is_me'] ?? false,
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
    );
  }
}

class ParticipantModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String joinedAt;
  final String? avatar;
  final bool isOnline;

  ParticipantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.avatar,
    required this.isOnline,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: json['joined_at'] ?? '',
      avatar: json['avatar'],
      isOnline: json['is_online'] ?? false,
    );
  }
}
