import 'package:flutter/material.dart';
import '../models/music.dart';
import '../services/admin_service.dart';

class AddEditMusicScreen extends StatefulWidget {
  static const routeName = '/admin-music-edit';

  const AddEditMusicScreen({super.key});

  @override
  State<AddEditMusicScreen> createState() => _AddEditMusicScreenState();
}

class _AddEditMusicScreenState extends State<AddEditMusicScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();
  final AdminService _service = AdminService();

  Music? _music;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Music && _music == null) {
      _music = args;
      _titleController.text = args.title;
      _artistController.text = args.artist;
      _lyricsController.text = args.lyrics;
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final title = _titleController.text.trim();
      final artist = _artistController.text.trim();
      if (title.isEmpty || artist.isEmpty) {
        setState(() {
          _error = 'Title and artist are required.';
        });
        return;
      }

      if (_music == null) {
        await _service.createMusic(
          title: title,
          artist: artist,
          lyrics: _lyricsController.text.trim(),
        );
      } else {
        await _service.updateMusic(
          _music!,
          title: title,
          artist: artist,
          lyrics: _lyricsController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (err) {
      setState(() {
        _error = 'Failed to save music.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _music != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Music' : 'Add Music')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: 'Artist',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lyricsController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Lyrics',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? 'Update Music' : 'Add Music'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
