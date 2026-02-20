import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sample/screens/sign_up_screen.dart';
import 'package:flutter_sample/services/auth_service.dart';

class _TestAuthClient implements AuthClient {
  @override
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    return 'User';
  }

  @override
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    return 'User';
  }

  @override
  Future<bool> isSuperAdmin() async => false;

  @override
  Future<bool> isAdmin() async => false;

  @override
  Future<String?> requestSuperAdmin() async => null;

  @override
  Future<String?> approveAdminRequest({
    required String userId,
    required String approvedBy,
  }) async {
    return null;
  }

  @override
  Future<String?> rejectAdminRequest({
    required String userId,
    required String approvedBy,
  }) async {
    return null;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Sign up screen renders inputs and button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SignUpScreen(authService: _TestAuthClient())),
    );

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });
}
