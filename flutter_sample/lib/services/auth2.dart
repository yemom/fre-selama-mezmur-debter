import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_sample/services/user.dart' as app_user;

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  app_user.User? _userFromFirebaseUser(auth.User? user) {
    return user != null ? app_user.User(uid: user.uid) : null;
  }

  Future<app_user.User?> signInEmailAndPass(
    String email,
    String password,
  ) async {
    try {
      auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      auth.User? user = userCredential.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  Future<app_user.User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      auth.User? user = userCredential.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return null;
    }
  }

  Future resetPass(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return null;
    }
  }
}
