import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/music.dart';
import '../../services/admin_service.dart';
import 'add_edit_music_screen.dart';
import 'admin_signup_form.dart';
import 'mannage_admin_request.dart';
import 'manage_categories_screen.dart';
import 'manage_music_screen.dart';
import 'manage_users_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  static const routeName = '/admin-home';

  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final role = (data['role'] as String? ?? 'admin')
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('-', '')
            .replaceAll('_', '');
        final isSuperAdmin = role == 'superadmin';

        return Scaffold(
          appBar: AppBar(
            title: const Text('ፍሬ ሰላማ ሰ/ት ቤት መዝሙር ደብተር - Admin'),
            actions: [
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _AdminDashboard(isSuperAdmin: isSuperAdmin),
                _AdminActionCards(
                  onAddMusic: () => Navigator.pushNamed(
                    context,
                    AddEditMusicScreen.routeName,
                  ),
                  onManageMusic: () =>
                      Navigator.pushNamed(context, ManageMusicScreen.routeName),
                  onManageCategories: () => Navigator.pushNamed(
                    context,
                    ManageCategoriesScreen.routeName,
                  ),
                  onCreateAdmin: isSuperAdmin
                      ? () => Navigator.pushNamed(
                          context,
                          AdminSignupForm.routeName,
                        )
                      : null,
                ),
                _AdminManagementCards(
                  isSuperAdmin: isSuperAdmin,
                  onOpenUsers: isSuperAdmin
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ManageUsersScreen(canEdit: true),
                          ),
                        )
                      : null,
                  onOpenRequests: isSuperAdmin
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageAdminRequestsScreen(),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminActionCards extends StatelessWidget {
  final VoidCallback onAddMusic;
  final VoidCallback onManageMusic;
  final VoidCallback onManageCategories;
  final VoidCallback? onCreateAdmin;

  const _AdminActionCards({
    required this.onAddMusic,
    required this.onManageMusic,
    required this.onManageCategories,
    this.onCreateAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 150,
            child: _ActionCard(
              title: 'Add Music & Lyrics',
              icon: Icons.library_music,
              onTap: onAddMusic,
            ),
          ),
          SizedBox(
            width: 150,
            child: _ActionCard(
              title: 'Manage Music',
              icon: Icons.library_music_outlined,
              onTap: onManageMusic,
            ),
          ),
          SizedBox(
            width: 150,
            child: _ActionCard(
              title: 'Manage Categories',
              icon: Icons.category_outlined,
              onTap: onManageCategories,
            ),
          ),
          if (onCreateAdmin != null)
            SizedBox(
              width: 150,
              child: _ActionCard(
                title: 'Register Admin',
                icon: Icons.person_add_alt_1,
                onTap: onCreateAdmin!,
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final bool isSuperAdmin;

  const _AdminDashboard({required this.isSuperAdmin});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Unknown date';
    }
    final date = timestamp.toDate();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminService();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<Category>>(
                  stream: service.watchCategories(),
                  builder: (context, snapshot) {
                    final total = snapshot.data?.length ?? 0;
                    return _StatCard(
                      title: 'Total Categories',
                      value: total.toString(),
                      icon: Icons.category_outlined,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<List<Music>>(
                  stream: service.watchMusic(),
                  builder: (context, snapshot) {
                    final total = snapshot.data?.length ?? 0;
                    return _StatCard(
                      title: 'Total Songs',
                      value: total.toString(),
                      icon: Icons.library_music_outlined,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pie_chart_outline),
                      const SizedBox(width: 8),
                      Text(
                        'Category Statistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Category>>(
                    stream: service.watchCategories(),
                    builder: (context, categorySnapshot) {
                      final categories = categorySnapshot.data ?? [];
                      return StreamBuilder<List<Music>>(
                        stream: service.watchMusic(),
                        builder: (context, musicSnapshot) {
                          final music = musicSnapshot.data ?? [];
                          if (categories.isEmpty) {
                            return const Text('No categories yet.');
                          }
                          final total = music.isEmpty ? 1 : music.length;
                          final counts = <String, int>{};
                          for (final item in music) {
                            final key = item.categoryId.isEmpty
                                ? 'Uncategorized'
                                : item.categoryId;
                            counts[key] = (counts[key] ?? 0) + 1;
                          }

                          return Column(
                            children: categories.map((category) {
                              final count = counts[category.id] ?? 0;
                              final percent = ((count / total) * 100).round();
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category.name.toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text('$count songs'),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text('$percent%'),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('music')
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text('No recent activity.');
                      }
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          final title = data['title'] as String? ?? 'Untitled';
                          final artist =
                              data['artist'] as String? ?? 'Unknown artist';
                          final createdAt = data['createdAt'] as Timestamp?;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.library_music),
                            title: Text(title),
                            subtitle: Text(
                              '$artist • ${_formatDate(createdAt)}',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _AdminManagementCards extends StatelessWidget {
  final bool isSuperAdmin;
  final VoidCallback? onOpenUsers;
  final VoidCallback? onOpenRequests;

  const _AdminManagementCards({
    required this.isSuperAdmin,
    this.onOpenUsers,
    this.onOpenRequests,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSuperAdmin) {
      return const SizedBox.shrink();
    }

    final service = AdminService();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        children: [
          StreamBuilder<List<AppUser>>(
            stream: service.watchUsers(),
            builder: (context, snapshot) {
              final total = snapshot.data?.length ?? 0;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Manage Users'),
                  subtitle: Text('$total total users'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenUsers,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AdminRequest>>(
            stream: service.watchAdminRequests(),
            builder: (context, snapshot) {
              final requests = snapshot.data ?? [];
              final pending = requests
                  .where((item) => item.status == 'pending')
                  .length;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Manage Admin Requests'),
                  subtitle: Text(
                    pending == 0
                        ? 'No pending admin requests'
                        : '$pending pending admin requests',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenRequests,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Colors.blueGrey),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
