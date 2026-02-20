import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AlbumFormScreen extends StatefulWidget {
  static const routeName = '/admin-album-form';

  const AlbumFormScreen({super.key});

  @override
  State<AlbumFormScreen> createState() => _AlbumFormScreenState();
}

class _AlbumFormScreenState extends State<AlbumFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final AdminService _service = AdminService();

  Album? _album;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Album && _album == null) {
      _album = args;
      _nameController.text = args.name;
      _artistController.text = args.artist;
      _descriptionController.text = args.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _artistController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final artist = _artistController.text.trim();
      if (name.isEmpty || artist.isEmpty) {
        setState(() {
          _error = 'Album name and artist are required.';
        });
        return;
      }

      if (_album == null) {
        await _service.createAlbum(
          name: name,
          artist: artist,
          description: _descriptionController.text.trim(),
        );
      } else {
        await _service.updateAlbum(
          id: _album!.id,
          name: name,
          artist: artist,
          description: _descriptionController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (err) {
      setState(() {
        _error = 'Failed to save album.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _album != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Album' : 'Add Album')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Album Name',
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
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
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
                    : Text(isEditing ? 'Update Album' : 'Add Album'),
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
