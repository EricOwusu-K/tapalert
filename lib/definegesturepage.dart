import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DefineGesturePage extends StatefulWidget {
  const DefineGesturePage({super.key});

  @override
  State<DefineGesturePage> createState() => _DefineGesturePageState();
}

class _DefineGesturePageState extends State<DefineGesturePage> {
  final TextEditingController _alertNameController = TextEditingController();
  String? _selectedCategory;
  String _detectedGesture = '';
  int _tapCount = 0;

  void _resetTapCountAfterDelay() {
    Future.delayed(const Duration(milliseconds: 400), () {
      _tapCount = 0;
    });
  }

  void _detectGesture(String gesture) {
    setState(() {
      _detectedGesture = gesture;
    });
  }

  Future<void> _saveGesture() async {
    final alertName = _alertNameController.text.trim();
    if (alertName.isEmpty ||
        _detectedGesture.isEmpty ||
        _selectedCategory == null)
      return;

    await FirebaseFirestore.instance.collection('gestureAlerts').add({
      'alertName': alertName,
      'gesture': _detectedGesture,
      'category': _selectedCategory,
    });

    _alertNameController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gesture saved successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Define Gesture")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to the Define Gesture page.\n\nFeel free to define a gesture alert with the following available gestures:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              "Supported Gestures:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "• Single Tap\n• Double Tap\n• Triple Tap\n• Long Press\n• Horizontal Swipe\n• Vertical Swipe",
            ),
            const SizedBox(height: 20),
            const Text(
              "Tap the box below to record a gesture:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                _tapCount++;
                if (_tapCount == 3) {
                  _detectGesture('tripleTap');
                } else {
                  _detectGesture('singleTap');
                }
                _resetTapCountAfterDelay();
              },
              onDoubleTap: () => _detectGesture('doubleTap'),
              onLongPress: () => _detectGesture('longPress'),
              onHorizontalDragEnd: (_) => _detectGesture('horizontalSwipe'),
              onVerticalDragEnd: (_) => _detectGesture('verticalSwipe'),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _detectedGesture.isEmpty
                        ? "Tap here to record gesture"
                        : "Gesture Recorded: $_detectedGesture",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _alertNameController,
              decoration: const InputDecoration(
                labelText: "Name of Alert",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                DropdownMenuItem(value: 'Fire', child: Text('Fire')),
                DropdownMenuItem(value: 'Police', child: Text('Police')),
                DropdownMenuItem(value: 'Panic', child: Text('Panic')),
                DropdownMenuItem(value: 'Custom', child: Text('Custom')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveGesture,
                icon: const Icon(Icons.save),
                label: const Text("Save Gesture"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
