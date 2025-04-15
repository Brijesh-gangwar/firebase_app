import 'package:firebase_app2/screens/auth/login_screen.dart';
import 'package:firebase_app2/screens/home_screen.dart';
import 'package:firebase_app2/screens/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show splash screen while checking auth state
          return const SplashScreen();
        } else if (snapshot.hasData) {
          // User is signed in
          return  HomePage();
        } else {
          // User is not signed in
          return const LoginScreen();
        }
      },
    );
  }
}
