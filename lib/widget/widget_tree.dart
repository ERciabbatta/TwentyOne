import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:twentyone/pages/profilo.dart';
import 'package:twentyone/pages/non_iscritto.dart';
import 'auth.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7A9CC6)),
            ),
          );
        }

        if (snapshot.data == null) {
          return const NonIscritto();
        }

        return Profilo();
      },
    );
  }
}
