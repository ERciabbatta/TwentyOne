import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled/profilo.dart';
import 'package:untitled/widget/MyBottomBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/widget/servizio_notifiche.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    final notifService = NotificationService();
    await notifService.init();
    await notifService.richiediPermessi();

    runApp(const MyApp());
  }, (error, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            'ERRORE:\n$error\n\nSTACK:\n$stack',
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ),
      ),
    ));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const _AuthGate(),
      routes: {
        '/profilo': (context) => Profilo(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _aspettaUtenteESchedula();
  }

  Future<void> _aspettaUtenteESchedula() async {
    await FirebaseAuth.instance.authStateChanges().first;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final notifService = NotificationService();
      await notifService.scheduleNotificheEventi();
      await notifService.scheduleMotivazionale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyBottomBar();
  }
}