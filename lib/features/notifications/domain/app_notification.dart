import '../../../core/network/json_reader.dart';

enum NotificationKind {
  info('INFO'),
  success('SUCCESS'),
  warning('WARNING'),
  error('ERROR');

  final String wireValue;
  const NotificationKind(this.wireValue);

  static NotificationKind fromWire(String? value) => enumFromWire(
    value,
    NotificationKind.values,
    (kind) => kind.wireValue,
    fallback: NotificationKind.info,
  );
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationKind type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json.requireString('id'),
        title: json.stringOr('title', 'Notification'),
        message: json.stringOr('message', ''),
        type: NotificationKind.fromWire(json.optionalString('type')),
        isRead: json.boolOr('isRead', false),
        createdAt: json.requireDateTime('createdAt'),
      );
}
