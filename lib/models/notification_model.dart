// Notification Models
class NotificationResponse {
  final bool status;
  final String message;
  final List<NotificationItem> notifications;

  NotificationResponse({
    required this.status,
    required this.message,
    required this.notifications,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final notificationsList = (json['data'] as List<dynamic>?)
            ?.map((item) => NotificationItem.fromJson(item))
            .toList() ??
        [];

    return NotificationResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      notifications: notificationsList,
    );
  }
}

class NotificationItem {
  final String message;
  final String createdAt;
  final bool markAsRead;
  final String notificationToken;

  NotificationItem({
    required this.message,
    required this.createdAt,
    required this.markAsRead,
    required this.notificationToken,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      markAsRead: json['markAsRead'] ?? false,
      notificationToken: json['notification_token']?.toString() ?? '',
    );
  }

  DateTime get createdAtDateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return createdAt;
    }
  }
}

