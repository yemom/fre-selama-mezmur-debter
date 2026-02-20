import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

abstract class AuthClient {
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  });

  Future<String?> login({required String email, required String password});
  Future<bool> isSuperAdmin();
  Future<bool> isAdmin();
  Future<String?> requestSuperAdmin();
  Future<String?> approveAdminRequest({
    required String userId,
    required String approvedBy,
  });

  Future<String?> rejectAdminRequest({
    required String userId,
    required String approvedBy,
  });

  Future<void> signOut();
}

class AuthService implements AuthClient {
  // Optional overrides to support testing/mocking without touching Firebase at construction time
  final auth.FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  auth.FirebaseAuth get _auth => _authOverride ?? auth.FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  AuthService({auth.FirebaseAuth? authClient, FirebaseFirestore? firestore})
    : _authOverride = authClient,
      _firestoreOverride = firestore;

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role, // "User" or "Admin"
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) return 'firebase_auth/unknown';

      // Keep role "User" until approved if Admin requested
      final initialRole = role.toLowerCase() == 'admin' ? 'User' : 'User';

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': initialRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (role.toLowerCase() == 'admin') {
        await _firestore.collection('adminRequests').doc(uid).set({
          'userId': uid,
          'status': 'pending', // pending | approved | rejected
          'requestedAt': FieldValue.serverTimestamp(),
          'approvedAt': null,
          'approvedBy': null,
        });
        return 'Admin'; // UI shows "pending approval"
      }

      return null; // success
    } on auth.FirebaseAuthException catch (e) {
      return 'firebase_auth/${e.code}';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) return 'firebase_auth/unknown';

      final snap = await _firestore.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      final roleRaw = (data['role'] as String?) ?? 'User';
      final normalized = roleRaw.trim().toLowerCase().replaceAll(' ', '');

      if (normalized == 'superadmin') return 'SuperAdmin';
      if (normalized == 'admin') return 'Admin';
      return 'User';
    } on auth.FirebaseAuthException catch (e) {
      return 'firebase_auth/${e.code}';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> isSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      // Check custom claims first
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? {};
      if (claims['superAdmin'] == true) return true;

      // Fallback to Firestore user document
      final snap = await _firestore.collection('users').doc(user.uid).get();
      final data = snap.data() ?? {};
      final role = (data['role'] as String?)?.toLowerCase().replaceAll(' ', '');
      final flag = (data['isSuperAdmin'] as bool?) ?? false;
      return flag || role == 'superadmin';
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? {};
      if (claims['admin'] == true || claims['superAdmin'] == true) return true;

      final snap = await _firestore.collection('users').doc(user.uid).get();
      final data = snap.data() ?? {};
      final role = (data['role'] as String?)?.toLowerCase().replaceAll(' ', '');
      return role == 'admin' || role == 'superadmin';
    } catch (_) {
      return false;
    }
  }

  Future<String?> requestSuperAdmin() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 'Not signed in';

      final reqRef = _firestore.collection('adminRequests').doc(uid);
      final existing = await reqRef.get();
      if (existing.exists) {
        final status = existing.data()?['status'] as String? ?? 'pending';
        return 'Request already $status';
      }
      await reqRef.set({
        'userId': uid,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });
      return 'Request submitted';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> approveAdminRequest({
    required String userId,
    required String approvedBy,
  }) async {
    try {
      final reqRef = _firestore.collection('adminRequests').doc(userId);
      final snap = await reqRef.get();
      if (!snap.exists) return 'Request not found';

      await reqRef.update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userId).update({
        'role': 'Admin',
      });
      return 'Approved';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> rejectAdminRequest({
    required String userId,
    required String approvedBy,
  }) async {
    try {
      final reqRef = _firestore.collection('adminRequests').doc(userId);
      final snap = await reqRef.get();
      if (!snap.exists) return 'Request not found';

      await reqRef.update({
        'status': 'rejected',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userId).update({'role': 'User'});
      return 'Rejected';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
