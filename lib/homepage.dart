import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _triggerGesture(String gestureType) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('gestureAlerts')
              .where('gesture', isEqualTo: gestureType)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final alert = querySnapshot.docs.first.data();
        final name = alert['alertName'] ?? 'Unnamed Alert';
        final category = alert['category'] ?? 'No Category';

        // ✅ Add alert log to 'alerts' collection
        await FirebaseFirestore.instance.collection('alerts').add({
          'name': name,
          'category': category,
          'time': Timestamp.now(),
        });

        // ✅ Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('🚨 $name ($category) alert triggered!')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // ❌ No match found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ No alert set for "$gestureType"'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ❌ Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              child: GestureDetector(
                onTap: () => _triggerGesture("singleTap"),
                onDoubleTap: () => _triggerGesture("doubleTap"),
                onLongPress: () => _triggerGesture("longPress"),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text(
                      'Tap here to trigger alert',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
