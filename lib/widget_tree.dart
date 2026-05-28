import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/profilo.dart';
import 'auth.dart';
import 'login_register.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginRegister();
        }

        return Profilo();
      },
    );
  }
}