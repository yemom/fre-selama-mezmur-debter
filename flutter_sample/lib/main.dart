import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_pending_screen.dart';
import 'screens/add_edit_music_screen.dart';
import 'screens/album_form_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/main_screen.dart';
import 'screens/music_list_screen.dart';
import 'screens/music_player_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      routes: {
        SignInScreen.routeName: (_) => const SignInScreen(),
        SignUpScreen.routeName: (_) => const SignUpScreen(),
        AdminHomeScreen.routeName: (_) => const AdminHomeScreen(),
        AdminPendingScreen.routeName: (_) => const AdminPendingScreen(),
        AddEditMusicScreen.routeName: (_) => const AddEditMusicScreen(),
        AlbumFormScreen.routeName: (_) => const AlbumFormScreen(),
        CategoryFormScreen.routeName: (_) => const CategoryFormScreen(),
        MainScreen.routeName: (_) => const MainScreen(),
        MusicListScreen.routeName: (_) => const MusicListScreen(),
        MusicPlayerScreen.routeName: (_) => const MusicPlayerScreen(),
        AdminLoginScreen.routeName: (_) => const AdminLoginScreen(),
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  String _normalizeRole(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const SignInScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = userSnapshot.data?.data() ?? {};
            final roleRaw = data['role'] as String? ?? 'client';
            final role = _normalizeRole(roleRaw);
            final approved = data['adminApproved'] == true;

            if (role == 'superadmin' || (role == 'admin' && approved)) {
              return const AdminHomeScreen();
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('adminRequests')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, requestSnapshot) {
                final requestData = requestSnapshot.data?.data() ?? {};
                final status = requestData['status'] as String?;
                if (status == 'pending') {
                  return const AdminPendingScreen();
                }
                return const MainScreen();
              },
            );
          },
        );
      },
    );
  }
}
