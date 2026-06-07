import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/pages/checkin.dart';
import 'package:untitled/pages/non_iscritto.dart';
import 'package:untitled/widget/MyBottomBar.dart';
import 'package:untitled/widget/servizio_notifiche.dart';
import 'package:untitled/widget/firebase_options.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final notifService = NotificationService();
    await notifService.init();
    await notifService.richiediPermessi();
    await notifService.scheduleCheckIn();

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
      title: 'TwentyOne',
      navigatorKey: NotificationService.navigatorKey,
      routes: {
        '/checkin': (context) => const CheckIn(),
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _notificheProgrammate = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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
          _notificheProgrammate = false;
          return const NonIscritto();
        }

        if (!_notificheProgrammate) {
          _notificheProgrammate = true;
          _scheduleNotifiche();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService().handleLaunchNotification();
          });
        }

        return const MyBottomBar();
      },
    );
  }

  Future<void> _scheduleNotifiche() async {
    final notifService = NotificationService();
    await notifService.scheduleNotificheEventi();
    await notifService.scheduleMotivazionale();
  }
}