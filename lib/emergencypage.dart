import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'definegesturepage.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final _auth = FirebaseAuth.instance;

  void _handleEmergencyTap(String category) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Alert not triggered. Please log in first."),
        ),
      );
      return;
    }

    // Step 1: Get user location
    Position? position;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Location error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to get location')));
      return;
    }

    // Step 2: Save alert to Firestore
    try {
      await FirebaseFirestore.instance.collection('alerts').add({
        'userId': user.uid,
        'category': category,
        'timestamp': Timestamp.now(),
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      });
    } catch (e) {
      print("Firestore error: $e");
    }

    // Step 3: Send push notification to each emergency contact
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final contactSnapshots =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('contacts')
              .get();

      String firstName = userDoc.data()?['firstName'] ?? 'Unknown';
      String surname = userDoc.data()?['surname'] ?? '';
      String fullName = '$firstName $surname';
      String time = DateTime.now().toString();
      String location = 'Lat ${position.latitude}, Long ${position.longitude}';

      for (var doc in contactSnapshots.docs) {
        final token = doc['token'];
        if (token != null && token is String && token.isNotEmpty) {
          await _sendPushNotification(
            token: token,
            title: "🚨 EMERGENCY ALERT FROM: $fullName",
            body: '''
Name: $firstName
Category: $category
Time: $time
GPS Location: $location
''',
          );
        }
      }
    } catch (e) {
      print("Push notification error: $e");
    }

    // Feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$category alert sent successfully!')),
    );
  }

  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'to': token,
        'title': title,
        'body': body,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Failed to send push notification: $e");
    }
  }

  Widget _buildEmergencyCard(
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleEmergencyTap(title),
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white24,
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
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

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
                      onPressed: () {
                        // Add phone call functionality
                      },
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
                      onPressed: () {
                        // Add location sharing logic
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_auth.currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You must be logged in to define a gesture."),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DefineGesturePage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Define Gesture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF736BFE),
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
