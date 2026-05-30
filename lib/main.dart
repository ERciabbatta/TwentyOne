import 'package:flutter/material.dart';
import 'package:untitled/profilo.dart';
import 'package:untitled/widget/MyBottomBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/widget/servizio_notifiche.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await NotificationService().init();
  await NotificationService().richiediPermessi();

  runApp(const MyApp());
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
      await NotificationService().scheduleNotificheEventi();
      await NotificationService().scheduleMotivazionale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyBottomBar();
  }
}