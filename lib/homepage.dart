import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:tapalert/notification_service.dart';

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

  Position? position;

  String buildGoogleMapsLink(Position position) {
    return 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
    }

    position = await Geolocator.getCurrentPosition();
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
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final firstName = userDoc.data()?['firstName'] ?? '';
      final surname = userDoc.data()?['surname'] ?? '';
      final fullname = '$firstName $surname';

      await _getCurrentLocation();

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Alert not sent.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('gestureAlerts')
              .where('gesture', isEqualTo: gestureType)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final alert = querySnapshot.docs.first.data();
        final gestureName = alert['alertName'] ?? 'Unnamed Alert';
        final category = alert['category'] ?? 'Uncategorized';

        final googleMapsUrl = buildGoogleMapsLink(position!);
        final now = DateTime.now();

        await FirebaseFirestore.instance.collection('alerts').add({
          'name': gestureName,
          'category': category,
          'time': now,
          'uid': user.uid,
          'map': googleMapsUrl,
        });

        final contactsSnap =
            await FirebaseFirestore.instance
                .collection('contacts')
                .where('ownerId', isEqualTo: user.uid)
                .get();

        if (contactsSnap.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ No contacts saved. Please add at least one."),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        for (final doc in contactsSnap.docs) {
          final contact = doc.data();
          final phone = contact['phone'];
          final token = contact['token'];

          if (phone != null && phone.toString().isNotEmpty) {
            await sendNotification(
              fullname: fullname,
              gestureName: gestureName,
              category: category,
              time: now.toString(),
              googleMapsUrl: googleMapsUrl,
              to: phone,
              recipientId: contact['uid'],
              type: 'sms',
            );
          }

          if (token != null && token.toString().isNotEmpty) {
            await sendNotification(
              fullname: fullname,
              gestureName: gestureName,
              category: category,
              time: now.toString(),
              googleMapsUrl: googleMapsUrl,
              to: token,
              recipientId: contact['uid'],
              type: 'push',
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 $gestureName ($category) alert triggered!'),
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

  // Gestures
  Offset? _panStart;
  Offset? _panEnd;

  void _handlePanStart(DragStartDetails details) {
    _panStart = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _panEnd = details.localPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_panStart == null || _panEnd == null) return;

    final dx = _panEnd!.dx - _panStart!.dx;
    final dy = _panEnd!.dy - _panStart!.dy;

    if (dx.abs() > dy.abs()) {
      _triggerGesture("horizontalSwipe");
    } else {
      _triggerGesture("verticalSwipe");
    }

    _panStart = null;
    _panEnd = null;
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
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
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
