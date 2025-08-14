import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 [Background] Message ID: ${message.messageId}');
}

/// Initializes Firebase Messaging (push notifications)
Future<void> initFirebaseMessaging() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permission (mostly for iOS)
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

  // Listen for messages in foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
      '🔔 [Foreground] Message: ${message.notification?.title} - ${message.notification?.body}',
    );
  });

  // When user taps on a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📬 [OpenedApp] User tapped notification');
    // TODO: Navigate to specific screen if needed
  });
}
