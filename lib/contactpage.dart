import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  Future<void> _addContactDialog() async {
    bool isFavorite = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: _relationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: isFavorite,
                          onChanged: (value) {
                            setState(() {
                              isFavorite = value!;
                            });
                          },
                        ),
                        const Text('Mark as Primary (Favorite)'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                final name = _nameController.text.trim();
                final phone = _phoneController.text.trim();
                final relationship = _relationshipController.text.trim();

                if (name.isEmpty || phone.isEmpty || relationship.isEmpty)
                  return;

                await FirebaseFirestore.instance.collection('contacts').add({
                  'name': name,
                  'phone': phone,
                  'relationship': relationship,
                  'isFavorite': isFavorite,
                  'createdAt': Timestamp.now(),
                });

                _nameController.clear();
                _phoneController.clear();
                _relationshipController.clear();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Contact'),
            content: const Text('Do you want to delete this contact?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('contacts')
          .doc(docId)
          .delete();
    }
  }

  Widget _buildContactCard(Map<String, dynamic> contactData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text(
            contactData['name'][0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(contactData['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contactData['phone']),
            Text(contactData['relationship']),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            if (contactData['isFavorite'] == true)
              const Icon(Icons.star, color: Colors.blue),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(contactData['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddContactButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add),
        label: const Text('Add Contact'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF736BFE),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: _addContactDialog,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('contacts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final allContacts =
            docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  },
                )
                .toList();

        final primaryContacts =
            allContacts
                .where((contact) => contact['isFavorite'] == true)
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Emergency Contacts'),
            actions: allContacts.isNotEmpty ? [_buildAddContactButton()] : [],
          ),
          body:
              allContacts.isEmpty
                  ? const Center(child: Text('No emergency contacts yet.'))
                  : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Text(
                        '${allContacts.length} contacts available',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (primaryContacts.isNotEmpty)
                        const Text(
                          'Primary Contacts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ...primaryContacts.map(_buildContactCard),
                      const SizedBox(height: 16),
                      const Text(
                        'All Contacts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      ...allContacts.map(_buildContactCard),
                    ],
                  ),
          floatingActionButton:
              allContacts.isEmpty
                  ? FloatingActionButton.extended(
                    onPressed: _addContactDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Contact'),
                  )
                  : null,
        );
      },
    );
  }
}
