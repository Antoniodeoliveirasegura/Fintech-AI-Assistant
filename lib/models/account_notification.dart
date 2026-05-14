// AccountNotification models a lightweight live update from the backend.
// In a real app this could arrive over WebSocket, SSE, or push notification.
class AccountNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final AccountNotificationType type;

  const AccountNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
  });

  factory AccountNotification.fromJson(Map<String, dynamic> json) {
    return AccountNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      type: AccountNotificationTypeX.fromJson(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'type': type.name,
  };
}

enum AccountNotificationType { payment, reminder, insight }

extension AccountNotificationTypeX on AccountNotificationType {
  static AccountNotificationType fromJson(String value) {
    switch (value) {
      case 'payment':
        return AccountNotificationType.payment;
      case 'reminder':
        return AccountNotificationType.reminder;
      case 'insight':
        return AccountNotificationType.insight;
      default:
        return AccountNotificationType.insight;
    }
  }
}
