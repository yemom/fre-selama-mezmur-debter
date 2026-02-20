import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sample/services/auth_service.dart';

class _InMemoryAuthStore implements AuthStore {
  final Map<String, Map<String, dynamic>> usersStore = {};
  final Map<String, Map<String, dynamic>> requestsStore = {};

  @override
  Future<Map<String, dynamic>?> getUser(String uid) async {
    return usersStore[uid];
  }

  @override
  Future<void> setUser(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    final existing = usersStore[uid] ?? {};
    usersStore[uid] = merge ? {...existing, ...data} : data;
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final existing = usersStore[uid] ?? {};
    usersStore[uid] = {...existing, ...data};
  }

  @override
  Future<Map<String, dynamic>?> getAdminRequest(String uid) async {
    return requestsStore[uid];
  }

  @override
  Future<void> setAdminRequest(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    final existing = requestsStore[uid] ?? {};
    requestsStore[uid] = merge ? {...existing, ...data} : data;
  }

  @override
  Future<void> updateAdminRequest(String uid, Map<String, dynamic> data) async {
    final existing = requestsStore[uid] ?? {};
    requestsStore[uid] = {...existing, ...data};
  }
}

void main() {
  test('signup creates user profile for client', () async {
    final auth = MockFirebaseAuth();
    final store = _InMemoryAuthStore();
    final service = AuthService(authClient: auth, store: store);

    final result = await service.signup(
      name: 'Test User',
      email: 'user@example.com',
      password: 'password123',
      role: 'User',
    );

    expect(result, 'User');
    final uid = auth.currentUser?.uid;
    expect(uid, isNotNull);

    final data = store.usersStore[uid] ?? {};
    expect(data['email'], 'user@example.com');
    expect(data['role'], 'client');
    expect(data['adminApproved'], true);
    expect(data['blocked'], false);
  });

  test('signup creates admin request for admin role', () async {
    final auth = MockFirebaseAuth();
    final store = _InMemoryAuthStore();
    final service = AuthService(authClient: auth, store: store);

    final result = await service.signup(
      name: 'Admin User',
      email: 'admin@example.com',
      password: 'password123',
      role: 'Admin',
    );

    expect(result, 'AdminPending');
    final uid = auth.currentUser?.uid;
    expect(uid, isNotNull);

    final userData = store.usersStore[uid] ?? {};
    expect(userData['role'], 'admin');
    expect(userData['adminApproved'], false);

    final requestData = store.requestsStore[uid] ?? {};
    expect(requestData['status'], 'pending');
    expect(requestData['email'], 'admin@example.com');
  });

  test('login returns Admin when approved admin', () async {
    final auth = MockFirebaseAuth();
    final store = _InMemoryAuthStore();
    final service = AuthService(authClient: auth, store: store);

    final cred = await auth.createUserWithEmailAndPassword(
      email: 'admin2@example.com',
      password: 'password123',
    );
    final uid = cred.user!.uid;
    store.usersStore[uid] = {'role': 'admin', 'adminApproved': true};

    final result = await service.login(
      email: 'admin2@example.com',
      password: 'password123',
    );

    expect(result, 'Admin');
  });

  test('login returns AdminPending when not approved', () async {
    final auth = MockFirebaseAuth();
    final store = _InMemoryAuthStore();
    final service = AuthService(authClient: auth, store: store);

    final cred = await auth.createUserWithEmailAndPassword(
      email: 'pending@example.com',
      password: 'password123',
    );
    final uid = cred.user!.uid;
    store.usersStore[uid] = {'role': 'admin', 'adminApproved': false};

    final result = await service.login(
      email: 'pending@example.com',
      password: 'password123',
    );

    expect(result, 'AdminPending');
  });

  test('login returns SuperAdmin for superadmin role', () async {
    final auth = MockFirebaseAuth();
    final store = _InMemoryAuthStore();
    final service = AuthService(authClient: auth, store: store);

    final cred = await auth.createUserWithEmailAndPassword(
      email: 'super@example.com',
      password: 'password123',
    );
    final uid = cred.user!.uid;
    store.usersStore[uid] = {'role': 'superadmin', 'adminApproved': true};

    final result = await service.login(
      email: 'super@example.com',
      password: 'password123',
    );

    expect(result, 'SuperAdmin');
  });

  test('login returns User for client role', () async {
    final auth = MockFirebaseAuth();
    final store = _InMemoryAuthStore();
    final service = AuthService(authClient: auth, store: store);

    final cred = await auth.createUserWithEmailAndPassword(
      email: 'client@example.com',
      password: 'password123',
    );
    final uid = cred.user!.uid;
    store.usersStore[uid] = {'role': 'client', 'adminApproved': false};

    final result = await service.login(
      email: 'client@example.com',
      password: 'password123',
    );

    expect(result, 'User');
  });
}
