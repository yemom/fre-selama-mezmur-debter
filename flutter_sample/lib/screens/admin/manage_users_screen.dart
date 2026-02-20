import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class ManageUsersScreen extends StatelessWidget {
  final bool canEdit;

  const ManageUsersScreen({super.key, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    final currentAuthUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<List<AppUser>>(
        stream: service.watchUsers(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = userSnapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final currentUser = currentAuthUser == null
              ? null
              : users
                    .where((user) => user.uid == currentAuthUser.uid)
                    .cast<AppUser?>()
                    .firstWhere((user) => user != null, orElse: () => null);
          final otherUsers = currentUser == null
              ? users
              : users.where((user) => user.uid != currentUser.uid).toList();

          return ListView(
            children: [
              if (currentUser != null) ...[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Current User',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _UserRow(
                  user: currentUser,
                  service: service,
                  canEdit: canEdit,
                  isCurrentUser: true,
                ),
                const Divider(height: 32),
              ],
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Users',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...otherUsers.map(
                (user) =>
                    _UserRow(user: user, service: service, canEdit: canEdit),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  final AdminService service;
  final bool canEdit;
  final bool isCurrentUser;

  const _UserRow({
    required this.user,
    required this.service,
    required this.canEdit,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(user.email.isEmpty ? user.uid : user.email),
      subtitle: Text(
        isCurrentUser
            ? 'You • Role: ${user.role} • Approved: ${user.adminApproved}'
            : 'Role: ${user.role} • Approved: ${user.adminApproved}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: user.role,
            items: const [
              DropdownMenuItem(value: 'client', child: Text('Client')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(
                value: 'super-admin',
                child: Text('Super Admin'),
              ),
            ],
            onChanged: canEdit
                ? (value) {
                    if (value == null || value == user.role) {
                      return;
                    }
                    service.setUserRole(user.uid, value);
                  }
                : null,
          ),
          IconButton(
            icon: Icon(user.blocked ? Icons.lock_open : Icons.lock_outline),
            onPressed: canEdit
                ? () => service.setUserBlocked(user.uid, !user.blocked)
                : null,
          ),
        ],
      ),
    );
  }
}
