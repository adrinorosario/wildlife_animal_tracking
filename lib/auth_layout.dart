import 'package:flutter/material.dart';
import 'package:wildlife_tracker/auth_services.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
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