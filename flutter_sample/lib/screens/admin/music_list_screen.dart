import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/music.dart';
import '../../services/music_service.dart';
import '../user/music_player_screen.dart';

class MusicListScreen extends StatefulWidget {
  static const routeName = '/music';

  const MusicListScreen({super.key});

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MusicService _service = MusicService();

  List<Music> _filter(List<Music> items) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      return items;
    }
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(query) ||
              item.artist.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music'),
        actions: [
          if (user != null)
            IconButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by title or artist',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Music>>(
              stream: _service.watchMusic(),
              builder: (context, musicSnapshot) {
                if (musicSnapshot.hasError) {
                  return const Center(child: Text('Failed to load music.'));
                }
                if (!musicSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = _filter(musicSnapshot.data!);
                if (items.isEmpty) {
                  return const Center(child: Text('No songs found.'));
                }

                return StreamBuilder<Set<String>>(
                  stream: _service.watchFavorites(),
                  builder: (context, favoriteSnapshot) {
                    final favorites = favoriteSnapshot.data ?? <String>{};
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isFavorite = favorites.contains(item.id);
                        return ListTile(
                          leading: item.coverUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    item.coverUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.music_note),
                          title: Text(item.title),
                          subtitle: Text(item.artist),
                          trailing: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                            ),
                            onPressed: () => _service.toggleFavorite(item),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              MusicPlayerScreen.routeName,
                              arguments: item,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
