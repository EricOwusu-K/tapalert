// firebasemsg.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

/// Handles background messages (must be a top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 [Background] Message ID: ${message.messageId}');
}

/// Call this in main() to initialize Firebase and set up messaging
Future<void> initFirebaseMessaging() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permissions (for iOS, does nothing on Android)
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Notification permission granted');
  } else {
    print('❌ Notification permission denied');
  }

  // Get FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  print('📲 FCM Token: $token');

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
      '🔔 [Foreground] Message: ${message.notification?.title} - ${message.notification?.body}',
    );
  });

  // Handle when app is opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📬 [OpenedApp] Message tapped!');
    // You can navigate to a specific page here if needed
  });
}
