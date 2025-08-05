import 'package:flutter/material.dart';
import 'package:tapalert/auth_service.dart';
import 'package:tapalert/loginsignuppage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isSharingLocation = false;
  bool isReceivingAlerts = false;
  User? user;

  @override
  void initState() {
    super.initState();
    user = AuthService().getCurrentUser();
  }

  void _refreshUser() {
    setState(() {
      user = AuthService().getCurrentUser();
    });
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Do you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Yes, log out"),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      await AuthService().signOut();
      _refreshUser();
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginSignUpPage()),
    ).then((_) => _refreshUser());
  }

  void _viewProfile() {
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfilePage(userId: user!.uid)),
      );
    }
  }

  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: user != null ? _viewProfile : null,
      child: Row(
        children: [
          const CircleAvatar(radius: 30, child: Icon(Icons.person)),
          const SizedBox(width: 16),
          Expanded(
            child:
                user != null
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user!.email ?? "No email",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(user!.uid, style: const TextStyle(fontSize: 12)),
                      ],
                    )
                    : const Text(
                      "Not logged in",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
          if (user != null)
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(label),
      trailing: Switch(
        value: value,
        onChanged: user != null ? onChanged : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileSection(),
            if (user == null)
              TextButton(
                onPressed: _navigateToLogin,
                child: const Text("Log in to manage your settings"),
              ),
            const SizedBox(height: 20),
            _buildToggle(
              label: "Share location with contacts",
              value: isSharingLocation,
              onChanged: (val) => setState(() => isSharingLocation = val),
            ),
            _buildToggle(
              label: "Receive alerts from others",
              value: isReceivingAlerts,
              onChanged: (val) => setState(() => isReceivingAlerts = val),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User details not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("${data['firstName']} ${data['surname']}"),
                const SizedBox(height: 16),
                const Text(
                  "Phone",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(data['phone'] ?? "N/A"),
                const SizedBox(height: 16),
                const Text(
                  "Email",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(data['email'] ?? "N/A"),
                const SizedBox(height: 16),
                const Text(
                  "UID",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(data['uid'] ?? "N/A"),
              ],
            ),
          );
        },
      ),
    );
  }
}
