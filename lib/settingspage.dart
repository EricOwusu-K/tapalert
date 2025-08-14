import 'package:flutter/material.dart';
import 'package:tapalert/firebase_auth.dart';
import 'package:tapalert/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapalert/userprofilepage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isSharingLocation = false;
  bool isReceivingAlerts = false;
  bool isAutoSendAlerts = false;
  bool isSharingGPS = false;

  User? user;
  String? fullName;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    user = AuthService().getCurrentUser();
    if (user != null) {
      _loadUserDetails();
    }
  }

  Future<void> _loadUserDetails() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        fullName = "${data['firstName']} ${data['surname']}";
        phoneNumber = data['phone'];
      });
    }
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
      MaterialPageRoute(builder: (_) => const LoginPage()),
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

  Widget _buildProfileCard() {
    String initials = "";
    if (fullName != null && fullName!.isNotEmpty) {
      final names = fullName!.split(" ");
      if (names.length >= 2) {
        initials = names[0][0] + names[1][0];
      } else if (names.isNotEmpty) {
        initials = names[0][0];
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: user != null ? Colors.blue : Colors.grey.shade300,
            child:
                user != null
                    ? Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : const Icon(Icons.person, color: Colors.black54, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                user != null
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName ?? "TapAlert User",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          phoneNumber ?? "",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        Text(
                          user!.email ?? "",
                          style: const TextStyle(color: Colors.black54),
                        ),
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
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _viewProfile,
              tooltip: "View Profile",
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      secondary: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: user != null ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Customize your TapAlert experience",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildProfileCard(),
            if (user == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text("Log in to manage your settings"),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Column(
                children: [
                  _buildSectionTitle("Emergency Settings"),
                  _buildToggleTile(
                    Icons.phone,
                    "Auto Send Alerts",
                    "Automatically send to emergency services",
                    isAutoSendAlerts,
                    (val) => setState(() => isAutoSendAlerts = val),
                  ),
                  _buildToggleTile(
                    Icons.location_on,
                    "Share Location",
                    "Include GPS location in alerts",
                    isSharingGPS,
                    (val) => setState(() => isSharingGPS = val),
                  ),
                  _buildToggleTile(
                    Icons.group,
                    "Share location with contacts",
                    "Your location will be shared with trusted contacts",
                    isSharingLocation,
                    (val) => setState(() => isSharingLocation = val),
                  ),
                  _buildToggleTile(
                    Icons.notifications_active,
                    "Receive alerts from others",
                    "Get notified when others send alerts",
                    isReceivingAlerts,
                    (val) => setState(() => isReceivingAlerts = val),
                  ),
                ],
              ),
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Log out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
