import 'package:flutter/material.dart';
import 'package:wildlife_tracker/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.pageIfNotConnected,
    required this.child,
  });

  final Widget pageIfNotConnected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authServices.value.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return child;
          } else {
            return pageIfNotConnected;
          }
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
