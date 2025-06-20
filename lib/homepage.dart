import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // Remove red background
        automaticallyImplyLeading: false, // No back button
        title: const Text(
          'TapAlert',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 141, 134, 134),
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Color.fromARGB(255, 41, 37, 37),
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            // TODO: Replace with alert logic
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Tap detected!")));
          },
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.red.shade100.withOpacity(0.3),
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Tap Here to Alert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
