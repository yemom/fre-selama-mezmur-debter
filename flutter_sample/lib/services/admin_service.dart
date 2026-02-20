import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/music.dart';

class AdminRequest {
  final String uid;
  final String email;
  final String status;
  final Timestamp? requestedAt;

  const AdminRequest({
    required this.uid,
    required this.email,
    required this.status,
    required this.requestedAt,
  });

  factory AdminRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminRequest(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      status: data['status'] ?? 'pending',
      requestedAt: data['requestedAt'] as Timestamp?,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String description;

  const Category({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
    );
  }
}

class Album {
  final String id;
  final String name;
  final String artist;
  final String description;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.description,
  });

  factory Album.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Album(
      id: doc.id,
      name: data['name'] ?? '',
      artist: data['artist'] ?? '',
      description: data['description'] ?? '',
    );
  }
}

class AppUser {
  final String uid;
  final String email;
  final String role;
  final bool adminApproved;
  final bool blocked;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.adminApproved,
    required this.blocked,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'client',
      adminApproved: data['adminApproved'] == true,
      blocked: data['blocked'] == true,
    );
  }
}

class AdminService {
  AdminService({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _db = db ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Stream<List<Music>> watchMusic() {
    return _db
        .collection('music')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Music.fromDoc).toList());
  }

  Stream<List<Category>> watchCategories() {
    return _db
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Category.fromDoc).toList());
  }

  Stream<List<AdminRequest>> watchAdminRequests() {
    return _db
        .collection('adminRequests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AdminRequest.fromDoc).toList());
  }

  Stream<List<Album>> watchAlbums() {
    return _db
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Album.fromDoc).toList());
  }

  Stream<List<AppUser>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppUser.fromDoc).toList());
  }

  Future<void> decideAdminRequest(String uid, bool approve) async {
    final callable = _functions.httpsCallable('approveAdminRequest');
    await callable.call({'uid': uid, 'approve': approve});
  }

  Future<void> setUserRole(String uid, String role) async {
    final callable = _functions.httpsCallable('setUserRole');
    await callable.call({'uid': uid, 'role': role});
  }

  Future<void> setUserBlocked(String uid, bool blocked) async {
    await _db.collection('users').doc(uid).set({
      'blocked': blocked,
    }, SetOptions(merge: true));
  }

  Future<void> createMusic({
    required String title,
    required String artist,
    String? album,
    String? categoryId,
    required String lyrics,
    Uint8List? audioBytes,
    String? audioExt,
    Uint8List? coverBytes,
    String? coverExt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not signed in');
    }

    final doc = _db.collection('music').doc();
    String audioUrl = '';
    if (audioBytes != null) {
      final ext = (audioExt == null || audioExt.isEmpty) ? 'mp3' : audioExt;
      final audioRef = _storage.ref().child('music/${doc.id}/audio.$ext');
      final audioTask = await audioRef.putData(audioBytes);
      audioUrl = await audioTask.ref.getDownloadURL();
    }

    String coverUrl = '';
    if (coverBytes != null) {
      final ext = (coverExt == null || coverExt.isEmpty) ? 'jpg' : coverExt;
      final coverRef = _storage.ref().child('covers/${doc.id}.$ext');
      final coverTask = await coverRef.putData(coverBytes);
      coverUrl = await coverTask.ref.getDownloadURL();
    }

    await doc.set({
      'title': title,
      'artist': artist,
      'album': album ?? '',
      'categoryId': categoryId ?? '',
      'lyrics': lyrics,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'likes': 0,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMusic(
    Music music, {
    required String title,
    required String artist,
    String? album,
    String? categoryId,
    required String lyrics,
    Uint8List? audioBytes,
    String? audioExt,
    Uint8List? coverBytes,
    String? coverExt,
  }) async {
    String audioUrl = music.audioUrl;
    if (audioBytes != null) {
      final ext = (audioExt == null || audioExt.isEmpty) ? 'mp3' : audioExt;
      final audioRef = _storage.ref().child('music/${music.id}/audio.$ext');
      final audioTask = await audioRef.putData(audioBytes);
      audioUrl = await audioTask.ref.getDownloadURL();
    }

    String coverUrl = music.coverUrl;
    if (coverBytes != null) {
      final ext = (coverExt == null || coverExt.isEmpty) ? 'jpg' : coverExt;
      final coverRef = _storage.ref().child('covers/${music.id}.$ext');
      final coverTask = await coverRef.putData(coverBytes);
      coverUrl = await coverTask.ref.getDownloadURL();
    }

    await _db.collection('music').doc(music.id).update({
      'title': title,
      'artist': artist,
      'album': album ?? music.album,
      'categoryId': categoryId ?? music.categoryId,
      'lyrics': lyrics,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMusic(Music music) async {
    if (music.coverUrl.isNotEmpty) {
      await _storage.refFromURL(music.coverUrl).delete();
    }
    if (music.audioUrl.isNotEmpty) {
      await _storage.refFromURL(music.audioUrl).delete();
    }
    await _db.collection('music').doc(music.id).delete();
  }

  Future<void> createCategory({
    required String name,
    required String description,
  }) async {
    await _db.collection('categories').add({
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    await _db.collection('categories').doc(id).update({
      'name': name,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  Future<void> createAlbum({
    required String name,
    required String artist,
    required String description,
  }) async {
    await _db.collection('albums').add({
      'name': name,
      'artist': artist,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAlbum({
    required String id,
    required String name,
    required String artist,
    required String description,
  }) async {
    await _db.collection('albums').doc(id).update({
      'name': name,
      'artist': artist,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAlbum(String id) async {
    await _db.collection('albums').doc(id).delete();
  }
}
