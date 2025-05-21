class NotificationModel {
  final int id;
  final String title;
  final String body;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? campaign;
  final Map<String, dynamic>? merchant;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.isRead,
    this.readAt,
    this.campaign,
    this.merchant,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Parse dates with timezone information
    DateTime parseSentAt() {
      final sentAtStr = json['sent_at'];
      if (sentAtStr == null) return DateTime.now();
      
      try {
        // Parse ISO string with timezone info - use it as is since it's already in local time
        return DateTime.parse(sentAtStr);
      } catch (e) {
        print('Error parsing sent_at date: $e');
        return DateTime.now();
      }
    }

    DateTime? parseReadAt() {
      final readAtStr = json['read_at'];
      if (readAtStr == null) return null;
      
      try {
        // Parse ISO string with timezone info - use it as is since it's already in local time
        return DateTime.parse(readAtStr);
      } catch (e) {
        print('Error parsing read_at date: $e');
        return null;
      }
    }

    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      sentAt: parseSentAt(),
      isRead: json['is_read'] ?? false,
      readAt: parseReadAt(),
      campaign: json['campaign'],
      merchant: json['merchant'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'sent_at': sentAt.toIso8601String(), // Don't convert to UTC since it's already in local time
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(), // Don't convert to UTC since it's already in local time
      'campaign': campaign,
      'merchant': merchant,
    };
  }
} 