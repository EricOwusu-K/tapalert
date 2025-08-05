import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  void _addContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();
    bool isPrimary = false;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Emergency Contact"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: relationshipController,
                    decoration: const InputDecoration(
                      labelText: "Relationship",
                    ),
                  ),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                    ),
                  ),
                  Row(
                    children: [
                      const Text("Mark as Primary"),
                      StatefulBuilder(
                        builder:
                            (context, setState) => Checkbox(
                              value: isPrimary,
                              onChanged:
                                  (val) =>
                                      setState(() => isPrimary = val ?? false),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Save"),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final relationship = relationshipController.text.trim();
                  final phone = phoneController.text.trim();
                  final user = FirebaseAuth.instance.currentUser;

                  if (name.isEmpty ||
                      relationship.isEmpty ||
                      phone.isEmpty ||
                      user == null)
                    return;

                  Navigator.pop(context);

                  final formattedPhone = phone.replaceAll(RegExp(r'\D'), '');

                  final userSnapshot =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .where('phone', isEqualTo: formattedPhone)
                          .limit(1)
                          .get();

                  final contactData = {
                    'name': name,
                    'relationship': relationship,
                    'phone': phone,
                    'isPrimary': isPrimary,
                    'createdAt': FieldValue.serverTimestamp(),
                    'ownerId': user.uid,
                  };

                  if (userSnapshot.docs.isNotEmpty) {
                    final matchedUser = userSnapshot.docs.first;
                    contactData['uid'] = matchedUser.id;
                    contactData['token'] = matchedUser['token'] ?? '';
                  }

                  await FirebaseFirestore.instance
                      .collection('contacts')
                      .add(contactData);
                },
              ),
            ],
          ),
    );
  }

  void _deleteContactDialog(BuildContext context, String contactId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Contact"),
            content: const Text(
              "Are you sure you want to delete this contact?",
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Delete"),
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('contacts')
                      .doc(contactId)
                      .delete();
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Please log in to manage contacts."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addContactDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('contacts')
                .where('ownerId', isEqualTo: currentUser.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No emergency contacts added yet."),
            );
          }

          final contacts = snapshot.data!.docs;
          final primaryContacts =
              contacts.where((doc) => doc['isPrimary'] == true).toList();
          final otherContacts =
              contacts.where((doc) => doc['isPrimary'] != true).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (primaryContacts.isNotEmpty) ...[
                const Text(
                  "Primary Contacts",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...primaryContacts
                    .map((doc) => _buildContactTile(context, doc))
                    .toList(),
                const SizedBox(height: 16),
              ],
              const Text(
                "All Contacts",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...otherContacts
                  .map((doc) => _buildContactTile(context, doc))
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      child: ListTile(
        title: Text(data['name'] ?? ''),
        subtitle: Text(
          "${data['relationship'] ?? ''} • ${data['phone'] ?? ''}",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteContactDialog(context, doc.id),
        ),
      ),
    );
  }
}
