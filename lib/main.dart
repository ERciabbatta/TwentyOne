import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/pages/checkin.dart';
import 'package:twentyone/pages/non_iscritto.dart';
import 'package:twentyone/pages/obiettivo.dart';
import 'package:twentyone/widget/MyBottomBar.dart';
import 'package:twentyone/widget/servizio_notifiche.dart';
import 'package:twentyone/widget/firebase_options.dart';

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

  // Stato onboarding obiettivo:
  // null  = ancora in caricamento
  // false = obiettivo mancante → mostra onboarding
  // true  = obiettivo presente → vai a MyBottomBar
  bool? _obiettivoPresente;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Attesa connessione Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        // Utente non loggato
        if (snapshot.data == null) {
          _notificheProgrammate = false;
          _obiettivoPresente = null; // reset per il prossimo login
          return const NonIscritto();
        }

        // Utente loggato — programma notifiche una volta sola
        if (!_notificheProgrammate) {
          _notificheProgrammate = true;
          _scheduleNotifiche();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService().handleLaunchNotification();
          });
          // Controlla se l'obiettivo è già stato impostato
          _verificaObiettivo(snapshot.data!.uid);
        }

        // Mentre verifichiamo l'obiettivo, mostra splash
        if (_obiettivoPresente == null) return const _Splash();

        // Obiettivo mancante → onboarding
        if (_obiettivoPresente == false) {
          return OnboardingObiettivo(
            onCompletato: () {
              // L'utente ha salvato l'obiettivo: vai all'app
              if (mounted) setState(() => _obiettivoPresente = true);
            },
          );
        }

        // Tutto ok → app normale
        return const MyBottomBar();
      },
    );
  }

  Future<void> _verificaObiettivo(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('utenti')
          .doc(uid)
          .get();
      final obiettivo = doc.data()?['obiettivo'] as String?;
      if (mounted) {
        setState(() => _obiettivoPresente =
            obiettivo != null && obiettivo.trim().isNotEmpty);
      }
    } catch (_) {
      // In caso di errore (es. offline al primo avvio) lasciamo passare
      if (mounted) setState(() => _obiettivoPresente = true);
    }
  }

  Future<void> _scheduleNotifiche() async {
    final notifService = NotificationService();
    await notifService.scheduleNotificheEventi();
    await notifService.scheduleMotivazionale();
  }
}

// Splash minimalista usato durante il caricamento
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF7A9CC6)),
      ),
    );
  }
}