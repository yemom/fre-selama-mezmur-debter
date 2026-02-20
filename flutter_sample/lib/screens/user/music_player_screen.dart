import 'package:flutter/material.dart';
import '../../models/music.dart';

class MusicPlayerScreen extends StatelessWidget {
  static const routeName = '/player';

  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = ModalRoute.of(context)?.settings.arguments as Music?;
    final titleText = (music?.title ?? '').trim().isEmpty ? ' ' : music!.title;
    final artistText = (music?.artist ?? '').trim().isEmpty
        ? ' '
        : music!.artist;

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Title', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Artist', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              artistText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('Lyrics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Text(
                          music?.lyrics ?? 'Lyrics will appear here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
