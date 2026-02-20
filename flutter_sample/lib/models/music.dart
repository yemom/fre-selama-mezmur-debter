import 'package:cloud_firestore/cloud_firestore.dart';

class Music {
  final String id;
  final String title;
  final String artist;
  final String categoryId;
  final String coverUrl;
  final String audioUrl;
  final String lyrics;

  const Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.categoryId,
    required this.coverUrl,
    required this.audioUrl,
    required this.lyrics,
  });

  factory Music.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Music(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      categoryId: (data['categoryId'] ?? data['category'] ?? '').toString(),
      coverUrl: data['coverUrl'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      lyrics: data['lyrics'] ?? '',
    );
  }
}
