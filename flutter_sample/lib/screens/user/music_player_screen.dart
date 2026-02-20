import 'package:flutter/material.dart';
import '../../models/music.dart';

class MusicPlayerScreen extends StatelessWidget {
  static const routeName = '/player';

  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = ModalRoute.of(context)?.settings.arguments as Music?;

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              music?.title ?? 'Select a song',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              music?.artist ?? 'Artist',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Center(
              child: music?.coverUrl.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        music!.coverUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.album,
                      size: 140,
                      color: Colors.blueGrey.shade200,
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.skip_previous, size: 32),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.play_circle_fill, size: 56),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.skip_next, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Lyrics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  music?.lyrics ?? 'Lyrics will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
