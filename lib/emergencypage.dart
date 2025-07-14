import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final TextEditingController _alertNameController = TextEditingController();
  final TextEditingController _gesturePatternController =
      TextEditingController();

  Future<void> _saveGestureAlert() async {
    final alertName = _alertNameController.text.trim();
    final gesture = _gesturePatternController.text.trim();

    if (alertName.isEmpty || gesture.isEmpty) return;

    await FirebaseFirestore.instance.collection('gestureAlerts').add({
      'alertName': alertName,
      'gesture': gesture,
    });

    _alertNameController.clear();
    _gesturePatternController.clear();
    Navigator.of(context).pop();
  }

  void _showAddGestureDialog() {
    String? selectedCategory;
    String detectedGesture = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Gesture Alert'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _alertNameController,
                    decoration: const InputDecoration(
                      labelText: 'Name of Alert',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Select Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Medical',
                        child: Text('Medical'),
                      ),
                      DropdownMenuItem(value: 'Fire', child: Text('Fire')),
                      DropdownMenuItem(value: 'Police', child: Text('Police')),
                      DropdownMenuItem(value: 'Panic', child: Text('Panic')),
                      DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                    ],
                    onChanged:
                        (value) => setState(() {
                          selectedCategory = value;
                        }),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() => detectedGesture = 'singleTap');
                    },
                    onDoubleTap: () {
                      setState(() => detectedGesture = 'doubleTap');
                    },
                    onLongPress: () {
                      setState(() => detectedGesture = 'longPress');
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(
                        child: Text(
                          detectedGesture.isEmpty
                              ? 'Tap here to record gesture'
                              : 'Gesture Recorded: $detectedGesture',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final alertName = _alertNameController.text.trim();
                if (alertName.isEmpty ||
                    detectedGesture.isEmpty ||
                    selectedCategory == null)
                  return;

                await FirebaseFirestore.instance
                    .collection('gestureAlerts')
                    .add({
                      'alertName': alertName,
                      'gesture': detectedGesture,
                      'category': selectedCategory,
                    });

                _alertNameController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyCard(
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        // Implement alert trigger logic here
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Alert')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select the type of emergency to send immediate help',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _buildEmergencyCard(
                'Medical Emergency',
                'Heart attack, stroke, severe injury',
                Colors.red,
                Icons.medical_services,
              ),
              _buildEmergencyCard(
                'Fire Emergency',
                'Fire, smoke, gas leak',
                Colors.deepOrange,
                Icons.local_fire_department,
              ),
              _buildEmergencyCard(
                'Personal Emergency',
                'Accident, trapped, lost',
                Colors.purple,
                Icons.person,
              ),
              _buildEmergencyCard(
                'Accident',
                'Car crash, injury, collision',
                Colors.orange,
                Icons.directions_car,
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.call),
                      label: const Text('Call Emergency Services'),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.location_on, color: Colors.green),
                      label: const Text(
                        'Share My Location',
                        style: TextStyle(color: Colors.green),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGestureDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
