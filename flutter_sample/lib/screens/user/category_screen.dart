import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/music.dart';
import '../../services/music_service.dart';
import 'music_player_screen.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final MusicService _service = MusicService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Music> _filter(List<Music> items) {
    final query = _searchController.text.toLowerCase().trim();
    final byCategory = items.where((music) {
      final matchesCategory =
          music.categoryId == widget.category.id ||
          music.categoryId.toLowerCase() == widget.category.name.toLowerCase();
      if (!matchesCategory) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return music.title.toLowerCase().contains(query) ||
          music.artist.toLowerCase().contains(query);
    }).toList();

    if (byCategory.isNotEmpty || query.isNotEmpty) {
      return byCategory;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(widget.category.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search music',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Music>>(
              stream: _service.watchMusic(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No songs found.'));
                }

                final items = _filter(snapshot.data!);
                if (items.isEmpty) {
                  return const Center(child: Text('No songs found.'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                      title: Text(item.title.isEmpty ? 'Untitled' : item.title),
                      subtitle: Text(
                        item.artist.isEmpty ? 'Unknown artist' : item.artist,
                      ),
                      trailing: const Icon(Icons.play_arrow),
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
            ),
          ),
        ],
      ),
    );
  }
}
