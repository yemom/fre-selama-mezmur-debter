import 'package:flutter/material.dart';
import '../../models/music.dart';
import '../../services/admin_service.dart';
import 'add_edit_music_screen.dart';

class ManageMusicScreen extends StatelessWidget {
  static const routeName = '/admin-manage-music';

  const ManageMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Music')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AddEditMusicScreen.routeName),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Music>>(
        stream: service.watchMusic(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No music found.'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.title.isEmpty ? 'Untitled' : item.title),
                subtitle: Text(item.artist.isEmpty ? 'Unknown' : item.artist),
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
                        content: const Text('This will remove the song.'),
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
      ),
    );
  }
}
