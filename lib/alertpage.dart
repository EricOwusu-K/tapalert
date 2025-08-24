import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  Future<void> _confirmAndDelete(
    BuildContext context,
    String collection,
    String docId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();
    }
  }

  Future<void> _confirmAndDeleteAll(
    BuildContext context,
    String collection,
    String userId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Delete All"),
            content: const Text(
              "Are you sure you want to delete all items in this section?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete All"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final query = FirebaseFirestore.instance
          .collection(collection)
          .where('recipientId', isEqualTo: userId);

      final snapshot = await query.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerts')),
        body: const Center(
          child: Text(
            'You must be logged in to view triggered alerts.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // NOTIFICATIONS SECTION
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .where(
                        'recipientId',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notifications = snapshot.data?.docs ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Notifications",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (notifications.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              tooltip: "Delete All Notifications",
                              onPressed:
                                  () => _confirmAndDeleteAll(
                                    context,
                                    'notifications',
                                    userId,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No notifications yet'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final docId = notifications[index].id;
                          final notif =
                              notifications[index].data()
                                  as Map<String, dynamic>;
                          final isRead = notif['read'] ?? false;
                          final title = notif['title'] ?? '';

                          return ListTile(
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight:
                                    isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  () => _confirmAndDelete(
                                    context,
                                    'notifications',
                                    docId,
                                  ),
                            ),
                            onTap: () {
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(docId)
                                  .update({'read': true});

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => NotificationDetailPage(
                                        title: title,
                                        body: notif['body'] ?? '',
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // ALERT HISTORY SECTION
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('alerts')
                      .where('uid', isEqualTo: userId)
                      .orderBy('time', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final alerts = snapshot.data?.docs ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Alert History",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (alerts.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              tooltip: "Delete All Alerts",
                              onPressed:
                                  () => _confirmAndDeleteAll(
                                    context,
                                    'alerts',
                                    userId,
                                  ),
                            ),
                        ],
                      ),
                    ),

                    if (alerts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No alerts have been triggered.'),
                      )
                    else
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final docId = alerts[index].id;
                          final alert =
                              alerts[index].data() as Map<String, dynamic>;
                          final name =
                              alert['name'] ??
                              alert['category'] ??
                              'Unknown Alert';
                          final category = alert['category'] ?? 'Uncategorized';
                          final timestamp = alert['time'] as Timestamp?;
                          final formattedTime =
                              timestamp != null
                                  ? DateFormat.yMMMd().add_jm().format(
                                    timestamp.toDate(),
                                  )
                                  : 'Unknown Time';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.redAccent,
                                  size: 30,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        category,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedTime,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _confirmAndDelete(
                                        context,
                                        'alerts',
                                        docId,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String body;

  const NotificationDetailPage({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(body, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
