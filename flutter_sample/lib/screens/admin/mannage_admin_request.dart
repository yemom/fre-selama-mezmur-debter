import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/services/auth_service.dart' as app_auth;
import 'package:flutter_sample/theme/theme.dart';

class ManageAdminRequestsScreen extends StatelessWidget {
  const ManageAdminRequestsScreen({
    super.key,
    this.firestore,
    this.authService,
  });

  static const routeName = '/admin-requests';

  final FirebaseFirestore? firestore;
  final app_auth.AuthClient? authService;

  @override
  Widget build(BuildContext context) {
    final service = authService ?? app_auth.AuthService();
    final store = firestore ?? FirebaseFirestore.instance;
    final approvedBy = FirebaseAuth.instance.currentUser?.uid ?? 'system';
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: store
            .collection('adminRequests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs
            ..sort((a, b) {
              final aTime =
                  (a['requestedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final bTime =
                  (b['requestedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
              return bTime.compareTo(aTime);
            });
          if (docs.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>? ?? {};
              final userId = d['userId'] as String? ?? docs[i].id;
              final status = d['status'] as String? ?? 'pending';

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: store.collection('users').doc(userId).get(),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: ListTile(
                        title: Text('Loading user...'),
                        subtitle: LinearProgressIndicator(),
                      ),
                    );
                  }

                  final userData = userSnap.data?.data();
                  final name = userData?['name'] as String? ?? 'Unknown user';
                  final email = userData?['email'] as String? ?? 'N/A';

                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(email), Text('Status: $status')],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status == 'pending')
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: AppTheme.successColor,
                              ),
                              onPressed: () async {
                                final msg = await service.approveAdminRequest(
                                  userId: userId,
                                  approvedBy: approvedBy,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg ?? 'Approved')),
                                );
                              },
                            ),
                          if (status == 'pending')
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppTheme.errorColor,
                              ),
                              onPressed: () async {
                                final msg = await service.rejectAdminRequest(
                                  userId: userId,
                                  approvedBy: approvedBy,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg ?? 'Rejected')),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
