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

abstract class AuthStore {
  Future<Map<String, dynamic>?> getUser(String uid);
  Future<void> setUser(String uid, Map<String, dynamic> data, {bool merge});
  Future<void> updateUser(String uid, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getAdminRequest(String uid);
  Future<void> setAdminRequest(
    String uid,
    Map<String, dynamic> data, {
    bool merge,
  });
  Future<void> updateAdminRequest(String uid, Map<String, dynamic> data);
}

class FirestoreAuthStore implements AuthStore {
  FirestoreAuthStore(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Future<void> setUser(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: merge));
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  @override
  Future<Map<String, dynamic>?> getAdminRequest(String uid) async {
    final doc = await _firestore.collection('adminRequests').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Future<void> setAdminRequest(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore
        .collection('adminRequests')
        .doc(uid)
        .set(data, SetOptions(merge: merge));
  }

  @override
  Future<void> updateAdminRequest(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('adminRequests').doc(uid).update(data);
  }
}

class AuthService implements AuthClient {
  final auth.FirebaseAuth? _authOverride;
  final AuthStore _store;
  String? _lastLoginDebug;

  auth.FirebaseAuth get _auth => _authOverride ?? auth.FirebaseAuth.instance;

  AuthService({
    auth.FirebaseAuth? authClient,
    FirebaseFirestore? firestore,
    AuthStore? store,
  }) : _authOverride = authClient,
       _store =
           store ?? FirestoreAuthStore(firestore ?? FirebaseFirestore.instance);

  String? get lastLoginDebugInfo => _lastLoginDebug;

  @override
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        return 'firebase_auth/unknown';
      }
      print('AUTH UID => ${cred.user?.uid}');
      print('FIRESTORE DOC UID => $uid');

      final wantsAdmin = role.toLowerCase() == 'admin';
      await _store.setUser(uid, {
        'name': name.trim(),
        'email': email.trim(),
        'role': wantsAdmin ? 'admin' : 'client',
        'adminApproved': !wantsAdmin,
        'blocked': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, merge: true);

      if (wantsAdmin) {
        await _store.setAdminRequest(uid, {
          'userId': uid,
          'email': email.trim(),
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
          'approvedAt': null,
          'approvedBy': null,
        }, merge: true);
        return 'AdminPending';
      }

      return 'User';
    } on auth.FirebaseAuthException catch (e) {
      return 'firebase_auth/${e.code}';
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        return 'firebase_auth/unknown';
      }
      final data = await _loadUserData(uid);
      final roleRaw = (data['role'] as String?) ?? 'client';
      final normalized = _normalizeRole(roleRaw);
      final approved = data['adminApproved'] == true;
      print('LOGIN ROLE DEBUG => $roleRaw | $normalized | approved=$approved');
      _setLoginDebug(
        uid: uid,
        email: cred.user?.email,
        roleRaw: roleRaw,
        normalizedRole: normalized,
        adminApproved: approved,
      );

      if (normalized == 'superadmin') {
        return 'SuperAdmin';
      }
      if (normalized == 'admin') {
        return approved ? 'Admin' : 'AdminPending';
      }
      return 'User';
    } on auth.FirebaseAuthException catch (e) {
      return 'firebase_auth/${e.code}';
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<bool> isSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? {};
      final roleClaim = claims['role'];
      final normalizedClaim = roleClaim is String
          ? _normalizeRole(roleClaim)
          : '';
      if (normalizedClaim == 'superadmin' || claims['superAdmin'] == true) {
        return true;
      }

      final data = await _loadUserData(user.uid);
      final role = _normalizeRole(data['role'] as String? ?? '');
      return role == 'superadmin';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? {};
      final roleClaim = claims['role'];
      final normalizedClaim = roleClaim is String
          ? _normalizeRole(roleClaim)
          : '';
      if (normalizedClaim == 'admin' ||
          normalizedClaim == 'superadmin' ||
          claims['admin'] == true ||
          claims['superAdmin'] == true) {
        return true;
      }

      final data = await _loadUserData(user.uid);
      final role = _normalizeRole(data['role'] as String? ?? '');
      final approved = data['adminApproved'] == true;
      return approved && (role == 'admin' || role == 'superadmin');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> requestSuperAdmin() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 'Not signed in';

      final existing = await _store.getAdminRequest(uid);
      if (existing != null) {
        final status = existing['status'] as String? ?? 'pending';
        return 'Request already $status';
      }
      await _store.setAdminRequest(uid, {
        'userId': uid,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });
      return 'Request submitted';
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<String?> approveAdminRequest({
    required String userId,
    required String approvedBy,
  }) async {
    try {
      final existing = await _store.getAdminRequest(userId);
      if (existing == null) return 'Request not found';

      await _store.updateAdminRequest(userId, {
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await _store.updateUser(userId, {'role': 'admin', 'adminApproved': true});
      return 'Approved';
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<String?> rejectAdminRequest({
    required String userId,
    required String approvedBy,
  }) async {
    try {
      final existing = await _store.getAdminRequest(userId);
      if (existing == null) return 'Request not found';

      await _store.updateAdminRequest(userId, {
        'status': 'rejected',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await _store.updateUser(userId, {
        'role': 'client',
        'adminApproved': false,
      });
      return 'Rejected';
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _normalizeRole(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '');
  }

  void _setLoginDebug({
    required String uid,
    String? email,
    String? roleRaw,
    String? normalizedRole,
    bool? adminApproved,
  }) {
    _lastLoginDebug = [
      'uid=$uid',
      if (email != null) 'email=$email',
      if (roleRaw != null) 'doc.role=$roleRaw',
      if (normalizedRole != null) 'doc.normalized=$normalizedRole',
      if (adminApproved != null) 'doc.adminApproved=$adminApproved',
    ].join(' | ');
  }

  Future<Map<String, dynamic>> _loadUserData(String uid) async {
    final data = await _store.getUser(uid);
    if (data == null) {
      throw Exception('User document not found');
    }
    return data;
  }
}
