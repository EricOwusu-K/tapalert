import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> _buildNotificationMessage({
  required String fullname,
  required String gestureName,
  required String category,
  required String time,
  required String googleMapsUrl,
  required String to,
  required String type,
  String? recipientId,
}) {
  return {
    'to': to,
    'type': type,
    'title': 'EMERGENCY ALERT FROM: $fullname',
    'body': '''Alert Name: $gestureName
Alert Type: $category
Time: $time
Map: $googleMapsUrl''',
    'timestamp': FieldValue.serverTimestamp(),
    'read': type == "push" ? false : null,
    'recipientId': recipientId,
  };
}

Future<void> sendNotification({
  required String fullname,
  required String gestureName,
  required String category,
  required String time,
  required String googleMapsUrl,
  required String to,
  required String type,
  String? recipientId,
}) async {
  final message = _buildNotificationMessage(
    fullname: fullname,
    gestureName: gestureName,
    category: category,
    time: time,
    googleMapsUrl: googleMapsUrl,
    to: to,
    type: type,
    recipientId: recipientId,
  );

  final collection = type == "sms" ? "smsQueue" : "notifications";
  await FirebaseFirestore.instance.collection(collection).add(message);
}
