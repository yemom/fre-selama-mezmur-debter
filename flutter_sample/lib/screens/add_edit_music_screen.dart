import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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

  String? _categoryId;

  Music? _music;
  Uint8List? _coverBytes;
  Uint8List? _audioBytes;
  String? _coverExt;
  String? _audioExt;
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
      _categoryId = args.categoryId.isEmpty ? null : args.categoryId;
      _lyricsController.text = args.lyrics;
    }
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    setState(() {
      _coverBytes = file.bytes;
      _coverExt = file.extension ?? 'jpg';
    });
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    setState(() {
      _audioBytes = file.bytes;
      _audioExt = file.extension ?? 'mp3';
    });
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

      if (_categoryId == null || _categoryId!.isEmpty) {
        setState(() {
          _error = 'Please select a category.';
        });
        return;
      }

      if (_music == null) {
        await _service.createMusic(
          title: title,
          artist: artist,
          categoryId: _categoryId,
          lyrics: _lyricsController.text.trim(),
          audioBytes: _audioBytes,
          audioExt: _audioExt,
          coverBytes: _coverBytes,
          coverExt: _coverExt,
        );
      } else {
        await _service.updateMusic(
          _music!,
          title: title,
          artist: artist,
          categoryId: _categoryId,
          lyrics: _lyricsController.text.trim(),
          audioBytes: _audioBytes,
          audioExt: _audioExt,
          coverBytes: _coverBytes,
          coverExt: _coverExt,
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
            StreamBuilder<List<Category>>(
              stream: _service.watchCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _categoryId,
                  items: categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _categoryId = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                );
              },
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickCover,
                    child: Text(
                      _coverBytes == null ? 'Upload Cover' : 'Cover Selected',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickAudio,
                    child: Text(
                      _audioBytes == null
                          ? 'Upload Audio (Optional)'
                          : 'Audio Selected',
                    ),
                  ),
                ),
              ],
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
