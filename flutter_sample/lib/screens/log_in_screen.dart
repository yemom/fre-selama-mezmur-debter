import 'package:flutter/material.dart';
import 'package:flutter_sample/screens/admin/admin_home_screen.dart';
import 'package:flutter_sample/screens/admin/admin_pending_screen.dart';
import 'package:flutter_sample/screens/sign_up_screen.dart';
import 'package:flutter_sample/screens/user/main_screen.dart';
import 'package:flutter_sample/services/auth_service.dart';
import 'package:flutter_sample/theme/theme.dart';

class Login extends StatefulWidget {
  const Login({super.key, required this.toggleView, this.authService});

  static const routeName = '/login';

  final void Function() toggleView;
  final AuthClient? authService;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late final AuthClient _authService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  void _login() async {
    setState(() => _isLoading = true);

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == 'SuperAdmin' || result == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }

    if (result != null && result.contains('firebase_auth/user-not-found')) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not registered. Please sign up.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } else if (result != null &&
        result.contains('firebase_auth/wrong-password')) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Failed: $result'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text(
          "ፍሬ ሰላማ ሰ/ት ቤት",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              children: [
                Image.network(
                  'https://img.freepik.com/premium-vector/login-icon-vector_942802-6305.jpg',
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                SizedBox(height: 10),

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: isPasswordHidden,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordHidden = !isPasswordHidden;
                        });
                      },
                      icon: Icon(
                        isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          // Call login function
                          child: const Text('Login'),
                        ),
                      ),

                SizedBox(height: 16),
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
                      child: const Text(
                        "Signup here",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
