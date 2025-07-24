import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pointerCount = 0;
  int _tapCount = 0;
  Offset? _initialFocalPoint;
  Offset? _lastTapPosition;
  DateTime? _lastTapTime;

  Future<void> _triggerGesture(String gestureType) async {
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

        final alertDoc = await FirebaseFirestore.instance
            .collection('alerts')
            .add({'name': name, 'category': category, 'time': DateTime.now()});

        final writtenAlert = await alertDoc.get();
        final data = writtenAlert.data();

        if (data != null) {
          final alertName = data['name'] ?? 'Unknown';
          final alertCategory = data['category'] ?? 'Unknown';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🚨 $alertName ($alertCategory) alert triggered!'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
        onSecondaryTap:
            () =>
                _triggerGesture("circleDraw"), // Placeholder for shape gesture
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
