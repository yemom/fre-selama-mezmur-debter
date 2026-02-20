import 'package:flutter/material.dart';
import 'package:flutter_sample/screens/sign_in_screen.dart';
import 'package:flutter_sample/screens/sign_up_screen.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showSignIn = true;

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showSignIn) {
      return const SignInScreen();
    } else {
      return const SignUpScreen();
    }
  }
}
