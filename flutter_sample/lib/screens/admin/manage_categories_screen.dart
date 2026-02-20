import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'category_form_screen.dart';

class ManageCategoriesScreen extends StatelessWidget {
  static const routeName = '/admin-manage-categories';

  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, CategoryFormScreen.routeName),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Category>>(
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
      ),
    );
  }
}
