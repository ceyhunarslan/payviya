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
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      sentAt: DateTime.parse(json['sent_at']),
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      campaign: json['campaign'],
      merchant: json['merchant'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'sent_at': sentAt.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'campaign': campaign,
      'merchant': merchant,
    };
  }
} 