import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/music.dart';

class MusicService {
  MusicService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Stream<List<Music>> watchMusic() {
    return _db
        .collection('music')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Music.fromDoc).toList());
  }

  Stream<Set<String>> watchFavorites() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(<String>{});
    }

    return _db
        .collection('favorites')
        .doc(uid)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<void> toggleFavorite(Music music) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('User not signed in');
    }

    final ref = _db
        .collection('favorites')
        .doc(uid)
        .collection('items')
        .doc(music.id);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }
}
