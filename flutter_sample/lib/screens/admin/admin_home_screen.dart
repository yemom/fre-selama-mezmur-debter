import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/music.dart';
import '../../services/admin_service.dart';
import 'add_edit_music_screen.dart';
import 'admin_signup_form.dart';
import 'mannage_admin_request.dart';
import 'category_form_screen.dart';
import 'manage_music_screen.dart';

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

        return DefaultTabController(
          length: isSuperAdmin ? 4 : 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('ፍሬ ሰላማ ሰ/ት ቤት መዝሙር ደብተር - Admin'),
              actions: [
                IconButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  const Tab(text: 'Music'),
                  const Tab(text: 'Categories'),
                  if (isSuperAdmin) const Tab(text: 'Users'),
                  if (isSuperAdmin) const Tab(text: 'Requests'),
                ],
              ),
            ),
            body: Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return Column(
                  children: [
                    _AdminActionCards(
                      onAddMusic: () => Navigator.pushNamed(
                        context,
                        AddEditMusicScreen.routeName,
                      ),
                      onManageMusic: () => Navigator.pushNamed(
                        context,
                        ManageMusicScreen.routeName,
                      ),
                      onManageCategories: () => controller.index = 1,
                      onCreateAdmin: isSuperAdmin
                          ? () => Navigator.pushNamed(
                              context,
                              AdminSignupForm.routeName,
                            )
                          : null,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          const _AdminMusicTab(),
                          const _AdminCategoriesTab(),
                          if (isSuperAdmin) const _AdminUsersTab(),
                          if (isSuperAdmin) const ManageAdminRequestsScreen(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                final tabIndex = controller.index;
                if (tabIndex > 1) {
                  return const SizedBox.shrink();
                }
                return FloatingActionButton(
                  onPressed: () {
                    if (tabIndex == 1) {
                      Navigator.pushNamed(
                        context,
                        CategoryFormScreen.routeName,
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        AddEditMusicScreen.routeName,
                      );
                    }
                  },
                  child: const Icon(Icons.add),
                );
              },
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

class _AdminMusicTab extends StatelessWidget {
  const _AdminMusicTab();

  @override
  Widget build(BuildContext context) {
    final service = AdminService();

    return StreamBuilder<List<Music>>(
      stream: service.watchMusic(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No music uploaded yet.'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.title),
              subtitle: Text(item.artist),
              onTap: () => Navigator.pushNamed(
                context,
                AddEditMusicScreen.routeName,
                arguments: item,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete music?'),
                      content: const Text(
                        'This will remove audio and metadata.',
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
                  if (confirmed == true) {
                    await service.deleteMusic(item);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context) {
    final service = AdminService();

    return StreamBuilder<List<AdminRequest>>(
      stream: service.watchAdminRequests(),
      builder: (context, requestSnapshot) {
        final requests = requestSnapshot.data ?? [];
        return StreamBuilder<List<AppUser>>(
          stream: service.watchUsers(),
          builder: (context, userSnapshot) {
            if (requestSnapshot.connectionState == ConnectionState.waiting ||
                userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = userSnapshot.data ?? [];
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Admin Requests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No admin requests.'),
                  )
                else
                  ...requests.map(
                    (request) => ListTile(
                      title: Text(request.email),
                      subtitle: Text('Status: ${request.status}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: request.status == 'pending'
                                ? () => service.decideAdminRequest(
                                    request.uid,
                                    true,
                                  )
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            onPressed: request.status == 'pending'
                                ? () => service.decideAdminRequest(
                                    request.uid,
                                    false,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Users',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No users found.'),
                  )
                else
                  ...users.map(
                    (user) => ListTile(
                      title: Text(user.email.isEmpty ? user.uid : user.email),
                      subtitle: Text(
                        'Role: ${user.role} • Approved: ${user.adminApproved}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButton<String>(
                            value: user.role,
                            items: const [
                              DropdownMenuItem(
                                value: 'client',
                                child: Text('Client'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Admin'),
                              ),
                              DropdownMenuItem(
                                value: 'super-admin',
                                child: Text('Super Admin'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null || value == user.role) {
                                return;
                              }
                              service.setUserRole(user.uid, value);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              user.blocked
                                  ? Icons.lock_open
                                  : Icons.lock_outline,
                            ),
                            onPressed: () =>
                                service.setUserBlocked(user.uid, !user.blocked),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AdminCategoriesTab extends StatelessWidget {
  const _AdminCategoriesTab();

  @override
  Widget build(BuildContext context) {
    final service = AdminService();

    return StreamBuilder<List<Category>>(
      stream: service.watchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Center(child: Text('No categories yet.'));
        }

        return ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              title: Text(category.name),
              subtitle: Text(category.description),
              onTap: () => Navigator.pushNamed(
                context,
                CategoryFormScreen.routeName,
                arguments: category,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete category?'),
                      content: const Text('This will remove the category.'),
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
                  if (confirmed == true) {
                    await service.deleteCategory(category.id);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
