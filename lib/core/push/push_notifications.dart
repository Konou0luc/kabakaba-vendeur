import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/data/devices_repository.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await ensureFirebaseInitialized();
}

Future<void> ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    print('KABA_PUSH: Firebase déjà initialisé (${Firebase.apps.length} app)');
    return;
  }
  print('KABA_PUSH: initializeApp…');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('KABA_PUSH: initializeApp OK');
}

class PushNotifications {
  PushNotifications(this._devices);

  final DevicesRepository _devices;
  final _plugin = FlutterLocalNotificationsPlugin();
  String? _token;
  bool _started = false;
  VoidCallback? onForegroundMessage;

  static const _channel = AndroidNotificationChannel(
    'kabakaba_default',
    'Kabakaba Vendeur',
    description: 'Commandes, retraits et compte cantine',
    importance: Importance.high,
  );

  Future<void> start() async {
    if (kIsWeb) {
      print('KABA_PUSH: ignoré (web)');
      return;
    }
    if (_started) {
      print('KABA_PUSH: start déjà fait');
      return;
    }
    try {
      await ensureFirebaseInitialized();
    } catch (error) {
      print('KABA_PUSH: Firebase non configuré: $error');
      return;
    }
    _started = true;
    print('KABA_PUSH: permissions…');

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.createNotificationChannel(_channel);
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.instance.onTokenRefresh.listen(syncToken);
    print('KABA_PUSH: start OK');
  }

  Future<void> syncToken([String? incoming]) async {
    print('KABA_PUSH: syncToken…');
    if (!_started) await start();
    if (!_started) {
      print('KABA_PUSH: syncToken abort (start a échoué)');
      return;
    }
    try {
      String? token = incoming;
      if (token == null || token.isEmpty) {
        Object? lastError;
        for (var attempt = 1; attempt <= 3; attempt++) {
          try {
            print('KABA_PUSH: getToken essai $attempt/3');
            token = await FirebaseMessaging.instance.getToken().timeout(
                  const Duration(seconds: 20),
                );
            if (token != null && token.isNotEmpty) break;
          } catch (error) {
            lastError = error;
            print('KABA_PUSH: getToken échec $attempt/3: $error');
            if (attempt < 3) {
              await Future<void>.delayed(Duration(seconds: attempt * 2));
            }
          }
        }
        if ((token == null || token.isEmpty) && lastError != null) {
          throw lastError;
        }
      }
      if (token == null || token.isEmpty) {
        print('KABA_PUSH: token vide (Play Services ?)');
        return;
      }
      print('KABA_PUSH: token ${token.substring(0, 16)}… (${token.length} car)');
      _token = token;
      await _devices.register(
        deviceToken: token,
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
      );
      print('KABA_PUSH: POST /devices OK');
    } catch (error) {
      print('KABA_PUSH: POST /devices échec: $error');
    }
  }

  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    await _devices.unregister(token);
    _token = null;
  }

  Future<void> _showForeground(RemoteMessage message) async {
    onForegroundMessage?.call();
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null && body == null) return;
    await _plugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

final pushNotificationsProvider = Provider<PushNotifications>((ref) {
  return PushNotifications(ref.watch(devicesRepositoryProvider));
});
