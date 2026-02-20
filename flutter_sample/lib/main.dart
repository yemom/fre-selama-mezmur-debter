import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/screens/admin/admin_home_screen.dart';
import 'package:flutter_sample/screens/admin/admin_pending_screen.dart';
import 'package:flutter_sample/screens/admin/admin_signup_form.dart';
import 'package:flutter_sample/screens/admin/category_form_screen.dart';
import 'package:flutter_sample/screens/admin/manage_music_screen.dart';
import 'package:flutter_sample/screens/user/main_screen.dart';
import 'package:flutter_sample/screens/user/about_developer_screen.dart';
import 'package:flutter_sample/screens/user/music_list_screen.dart';
import 'package:flutter_sample/screens/user/music_player_screen.dart';
import 'package:flutter_sample/theme/theme.dart';
import 'package:flutter_sample/widgets/user_background.dart';
import 'firebase_options.dart';
import 'screens/add_edit_music_screen.dart';

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
      title: 'ፍሬ ሰላማ ሰ/ት ቤት መዝሙር ደብተር',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routes: {
        SignInScreen.routeName: (_) => const SignInScreen(),
        SignUpScreen.routeName: (_) => const SignUpScreen(),
        AdminHomeScreen.routeName: (_) => const AdminHomeScreen(),
        AdminPendingScreen.routeName: (_) => const AdminPendingScreen(),
        AdminSignupForm.routeName: (_) => const AdminSignupForm(),
        ManageMusicScreen.routeName: (_) => const ManageMusicScreen(),
        AddEditMusicScreen.routeName: (_) => const AddEditMusicScreen(),
        CategoryFormScreen.routeName: (_) => const CategoryFormScreen(),
        MainScreen.routeName: (_) => const UserBackground(child: MainScreen()),
        AboutDeveloperScreen.routeName: (_) => const AboutDeveloperScreen(),
        MusicListScreen.routeName: (_) => const MusicListScreen(),
        MusicPlayerScreen.routeName: (_) => const MusicPlayerScreen(),
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
                return const UserBackground(child: MainScreen());
              },
            );
          },
        );
      },
    );
  }
}
