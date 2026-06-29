class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Check if userId is a populated object
    String uId = '';
    String? uName;
    String? uEmail;

    final userObj = json['userId'];
    if (userObj is Map<String, dynamic>) {
      uId = userObj['_id']?.toString() ?? '';
      uName = userObj['name']?.toString();
      uEmail = userObj['email']?.toString();
    } else if (userObj != null) {
      uId = userObj.toString();
    }

    return AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: uId,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
      userName: uName,
      userEmail: uEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
