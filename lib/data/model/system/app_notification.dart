import '../../../core/utils/json_x.dart';

enum NotificationCategory { order, promotion, system, warranty, unknown }

/// Thông báo trong hộp thư của app (đồng bộ với push OneSignal).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.category = NotificationCategory.system,
    this.imageUrl = '',
    this.deepLink = '',
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json.str(['id', 'notificationId']),
        title: json.str(['title', 'heading']),
        body: json.str(['body', 'content', 'message']),
        createdAt: json.date(['createdAt', 'sentAt']) ?? DateTime.now(),
        category: switch (json.str(['category', 'type']).toLowerCase()) {
          'order' => NotificationCategory.order,
          'promotion' || 'promo' => NotificationCategory.promotion,
          'warranty' => NotificationCategory.warranty,
          'system' => NotificationCategory.system,
          _ => NotificationCategory.unknown,
        },
        imageUrl: json.str(['imageUrl', 'image']),
        deepLink: json.str(['deepLink', 'url', 'link']),
        isRead: json.flag(['isRead', 'read']),
      );

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationCategory category;
  final String imageUrl;
  final String deepLink;
  final bool isRead;

  AppNotification markRead() => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        category: category,
        imageUrl: imageUrl,
        deepLink: deepLink,
        isRead: true,
      );
}
