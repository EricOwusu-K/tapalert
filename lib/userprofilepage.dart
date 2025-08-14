import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      _firstNameController.text = data['firstName'] ?? '';
      _surnameController.text = data['surname'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
          'firstName': _firstNameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        });

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "First Name",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(hintText: "Enter First Name"),
              ),
              const SizedBox(height: 16),

              const Text(
                "Last Name",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _surnameController,
                decoration: const InputDecoration(hintText: "Enter Last Name"),
              ),
              const SizedBox(height: 16),

              const Text(
                "Phone",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: "Enter Phone Number",
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              const Text(
                "Email",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: "Enter Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
