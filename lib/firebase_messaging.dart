import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 [Background] Message ID: ${message.messageId}');
}

Future<void> initFirebaseMessaging() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Notification permission granted');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('⚠️ Provisional notification permission granted');
  } else {
    print('❌ Notification permission denied');
  }

  // Get and print FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  print('📲 FCM Token: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
      '🔔 [Foreground] Message: ${message.notification?.title} - ${message.notification?.body}',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📬 [OpenedApp] User tapped notification');
  });
}
