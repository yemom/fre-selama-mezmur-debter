import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/screens/admin/admin_home_screen.dart';
import 'package:flutter_sample/screens/admin/admin_pending_screen.dart';
import 'package:flutter_sample/screens/user/main_screen.dart';
import '../services/auth_service.dart';

import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  static const routeName = '/sign-in';

  final AuthClient? authService;

  const SignInScreen({super.key, this.authService});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final AuthClient _authService;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  void _login() async {
    setState(() => _isLoading = true);

    final result = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (result == 'SuperAdmin' ||
        result == 'Admin' ||
        result == 'AdminPending' ||
        result == 'User') {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          throw Exception('User not signed in');
        }
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data();
        if (data == null || !data.containsKey('role')) {
          throw Exception('Role missing in user document');
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }
    }

    if (result == 'SuperAdmin' || result == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminHomeScreen()),
      );
      return;
    }

    if (result == 'AdminPending') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPendingScreen()),
      );
      return;
    }

    if (result == 'User') {
      Navigator.pushReplacementNamed(context, MainScreen.routeName);
      return;
    }

    String message = 'Login failed: $result';
    if (result == 'firebase_auth/user-not-found') {
      message = 'User not registered. Please sign up.';
    } else if (result == 'firebase_auth/wrong-password') {
      message = 'Invalid email or password.';
    } else if (result == 'firebase_auth/invalid-email') {
      message = 'Invalid email address.';
    } else if (result == 'Exception: User document not found') {
      message = 'Account is missing a user profile document.';
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ?? Colors.white;
    return Scaffold(
      appBar: AppBar(title: const Text('ፍሬ ሰላማ ሰ/ት ቤት መዝሙር ደብተር')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'photo_2024-09-27_00-18-20.jpg',
                                height: 140,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: _isPasswordHidden,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordHidden = !_isPasswordHidden;
                                      });
                                    },
                                    icon: Icon(
                                      _isPasswordHidden
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        child: const Text('Login'),
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have an account? "),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SignUpScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Signup here',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
