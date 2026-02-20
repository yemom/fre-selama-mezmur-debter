import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main';

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music & Lyrics'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          _searchBar(),
          Expanded(child: _musicList(context)),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search song or artist',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _musicList(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('music')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No songs found.'));
        }

        final query = _searchController.text.toLowerCase().trim();
        final songs = snapshot.data!.docs.where((doc) {
          if (query.isEmpty) {
            return true;
          }
          final data = doc.data();
          final title = (data['title'] ?? '').toString().toLowerCase();
          final artist = (data['artist'] ?? '').toString().toLowerCase();
          return title.contains(query) || artist.contains(query);
        }).toList();

        if (songs.isEmpty) {
          return const Center(child: Text('No matching songs.'));
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return _songTile(context, songs[index]);
          },
        );
      },
    );
  }

  Widget _songTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> song,
  ) {
    final data = song.data();
    final coverUrl = (data['coverUrl'] ?? '') as String;
    final title = (data['title'] ?? '') as String;
    final artist = (data['artist'] ?? '') as String;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: coverUrl.isNotEmpty ? NetworkImage(coverUrl) : null,
        child: coverUrl.isEmpty ? const Icon(Icons.music_note) : null,
      ),
      title: Text(title.isEmpty ? 'Untitled' : title),
      subtitle: Text(artist.isEmpty ? 'Unknown artist' : artist),
      trailing: const Icon(Icons.play_arrow),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
        );
      },
    );
  }
}

class SongDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> song;

  const SongDetailScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final data = song.data();
    final title = (data['title'] ?? '') as String;
    final artist = (data['artist'] ?? '') as String;
    final lyrics = (data['lyrics'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(title: Text(title.isEmpty ? 'Song' : title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.music_note, size: 100)),
            const SizedBox(height: 20),
            Text(
              artist.isEmpty ? 'Unknown artist' : artist,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Center(
              child: IconButton(
                icon: const Icon(Icons.play_circle, size: 64),
                onPressed: () {
                  // TODO: add audio player logic.
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lyrics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  lyrics.isEmpty ? 'No lyrics available.' : lyrics,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
