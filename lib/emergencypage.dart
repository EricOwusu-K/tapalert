import 'package:flutter/material.dart';
import 'definegesturepage.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
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
              minimumSize: const Size(180, 50), // Width, Height
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
