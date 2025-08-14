import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  String _formatPhoneNumber(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '233${digits.substring(1)}';
    }
    if (!digits.startsWith('+')) {
      digits = '+$digits';
    }
    return digits;
  }

  Future<void> _addContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final otherRelationshipController = TextEditingController();
    bool isPrimary = false;

    String selectedRelationship = 'Mother';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRelationship,
                      decoration: const InputDecoration(
                        labelText: "Relationship",
                      ),
                      items:
                          [
                                'Mother',
                                'Father',
                                'Sister',
                                'Brother',
                                'Husband',
                                'Wife',
                                'Guardian',
                                'Other',
                              ]
                              .map(
                                (rel) => DropdownMenuItem(
                                  value: rel,
                                  child: Text(rel),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRelationship = value!;
                        });
                      },
                    ),
                    if (selectedRelationship == 'Other')
                      TextField(
                        controller: otherRelationshipController,
                        decoration: const InputDecoration(
                          labelText: "Specify relationship",
                        ),
                      ),
                    Row(
                      children: [
                        Checkbox(
                          value: isPrimary,
                          onChanged: (value) {
                            setState(() {
                              isPrimary = value ?? false;
                            });
                          },
                        ),
                        const Text('Primary Contact'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    String name = nameController.text.trim();
                    String phone = _formatPhoneNumber(
                      phoneController.text.trim(),
                    );
                    String relationship =
                        selectedRelationship == 'Other'
                            ? otherRelationshipController.text.trim()
                            : selectedRelationship;

                    if (name.isNotEmpty && phone.isNotEmpty && user != null) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('contacts')
                            .add({
                              'ownerId': user!.uid,
                              'name': name,
                              'phone': phone,
                              'relationship': relationship,
                              'isPrimary': isPrimary,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact added successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add contact: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editContactDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name'] ?? '');
    final phoneController = TextEditingController(
      text: _formatPhoneNumber(data['phone'] ?? ''),
    );
    final otherRelationshipController = TextEditingController();
    bool isPrimary = data['isPrimary'] ?? false;

    String selectedRelationship = data['relationship'] ?? 'Mother';
    if (![
      'Mother',
      'Father',
      'Sister',
      'Brother',
      'Husband',
      'Wife',
      'Guardian',
      'Other',
    ].contains(selectedRelationship)) {
      selectedRelationship = 'Other';
      otherRelationshipController.text = data['relationship'] ?? '';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRelationship,
                      decoration: const InputDecoration(
                        labelText: "Relationship",
                      ),
                      items:
                          [
                                'Mother',
                                'Father',
                                'Sister',
                                'Brother',
                                'Husband',
                                'Wife',
                                'Guardian',
                                'Other',
                              ]
                              .map(
                                (rel) => DropdownMenuItem(
                                  value: rel,
                                  child: Text(rel),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRelationship = value!;
                        });
                      },
                    ),
                    if (selectedRelationship == 'Other')
                      TextField(
                        controller: otherRelationshipController,
                        decoration: const InputDecoration(
                          labelText: "Specify relationship",
                        ),
                      ),
                    Row(
                      children: [
                        Checkbox(
                          value: isPrimary,
                          onChanged: (value) {
                            setState(() {
                              isPrimary = value ?? false;
                            });
                          },
                        ),
                        const Text('Primary Contact'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    String name = nameController.text.trim();
                    String phone = _formatPhoneNumber(
                      phoneController.text.trim(),
                    );
                    String relationship =
                        selectedRelationship == 'Other'
                            ? otherRelationshipController.text.trim()
                            : selectedRelationship;

                    if (name.isNotEmpty && phone.isNotEmpty) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('contacts')
                            .doc(doc.id)
                            .update({
                              'name': name,
                              'phone': phone,
                              'relationship': relationship,
                              'isPrimary': isPrimary,
                            });
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact updated successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update contact: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteContact(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Contact'),
            content: const Text(
              'Are you sure you want to delete this contact?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('contacts')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete contact: $e')));
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your contacts')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('contacts')
                .where('ownerId', isEqualTo: userId)
                .orderBy('isPrimary', descending: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No contacts found'));
          }

          final contacts = snapshot.data!.docs;
          final primaryContacts =
              contacts.where((doc) => doc['isPrimary'] == true).toList();

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
                    .map((doc) => _buildContactTile(doc))
                    .toList(),
                const SizedBox(height: 16),
              ],
              const Text(
                "All Contacts",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...contacts.map((doc) => _buildContactTile(doc)).toList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContactDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContactTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListTile(
      title: Text("${data['name']} (${data['relationship']})"),
      subtitle: Text(data['phone']),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editContactDialog(doc),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteContact(doc.id),
          ),
        ],
      ),
    );
  }
}
