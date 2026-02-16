import 'package:flutter/material.dart';
import 'package:wildlife_tracker/auth_services.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
=======
>>>>>>> origin/master

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
<<<<<<< HEAD
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
=======
    this.pageIfNotConnected,
  });

  final Widget pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: authServices, builder: (context, authServices, child){
      Widget widget;
      
    });
  }
}
>>>>>>> origin/master
