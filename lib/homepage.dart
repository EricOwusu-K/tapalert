import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pointerCount = 0;
  int _tapCount = 0;
  Offset? _lastTapPosition;
  DateTime? _lastTapTime;

  Future<String> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'Location not available';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return 'Location permission denied';
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    return '${position.latitude}, ${position.longitude}';
  }

  Future<void> _sendPushNotification(String token, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'to': token,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _triggerGesture(String gestureType) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please log in to send alerts"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('gestureAlerts')
              .where('gesture', isEqualTo: gestureType)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final alert = querySnapshot.docs.first.data();
        final name = alert['alertName'] ?? 'Unnamed Alert';
        final category = alert['category'] ?? 'Uncategorized';

        await FirebaseFirestore.instance.collection('alerts').add({
          'name': name,
          'category': category,
          'time': DateTime.now(),
          'uid': user.uid,
        });

        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        final fullName =
            "${userDoc['firstName'] ?? 'Unknown'} ${userDoc['surname'] ?? ''}";
        final time = DateTime.now();
        final location = await _getCurrentLocation();

        final message = '''
EMERGENCY ALERT FROM: $fullName
Name: $name
Category: $category
Time: $time
GPS Location: $location
''';

        final contactsSnap =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('contacts')
                .get();

        for (final doc in contactsSnap.docs) {
          final contact = doc.data();
          final token = contact['token'];
          final phone = contact['phone'];

          if (token != null && token.toString().isNotEmpty) {
            await _sendPushNotification(token, message);
          } else if (phone != null) {
            await FirebaseFirestore.instance.collection('smsQueue').add({
              'to': phone,
              'message': message,
              'queuedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 $name ($category) alert triggered!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ No alert set for "$gestureType"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
      );
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      _triggerGesture("horizontalSwipe");
    } else {
      _triggerGesture("verticalSwipe");
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      _pointerCount++;
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_pointerCount == 2) {
      _triggerGesture("twoFingerSwipe");
      _triggerGesture("twoFingerTap");
    } else if (_pointerCount == 3) {
      _triggerGesture("threeFingerSwipe");
    }
    setState(() {
      _pointerCount = max(0, _pointerCount - 1);
    });
  }

  void _handleTripleTap(TapUpDetails details) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(seconds: 1) &&
        _lastTapPosition != null &&
        (details.globalPosition - _lastTapPosition!).distance < 50) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }

    _lastTapTime = now;
    _lastTapPosition = details.globalPosition;

    if (_tapCount == 3) {
      _triggerGesture("tripleTap");
      _tapCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      child: GestureDetector(
        onTap: () => _triggerGesture("singleTap"),
        onDoubleTap: () => _triggerGesture("doubleTap"),
        onTapUp: _handleTripleTap,
        onLongPress: () => _triggerGesture("longPress"),
        onPanUpdate: _handlePanUpdate,
        onSecondaryTap: () => _triggerGesture("circleDraw"),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'TapAlert',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF736BFE),
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset('assets/logo.png', width: 40, height: 40),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        'Use gestures to trigger alerts',
                        style: TextStyle(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
