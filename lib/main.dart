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
import 'package:twentyone/widget/app_theme.dart';
import 'package:twentyone/widget/theme_provider.dart';
import 'package:twentyone/widget/app_colors.dart';
import 'package:google_sign_in/google_sign_in.dart';

final themeProvider = ThemeProvider();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await themeProvider.caricaPreferenza();

    await GoogleSignIn.instance.initialize(
      serverClientId: '100839405357-foig1d53c1rp7b1hat8414fbd9kcfivn.apps.googleusercontent.com',
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
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'TwentyOne',
          navigatorKey: NotificationService.navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          routes: {
            '/checkin': (context) => const CheckIn(),
          },
          home: const AuthGate(),
        );
      },
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

  bool? _obiettivoPresente;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        if (snapshot.data == null) {
          _notificheProgrammate = false;
          _obiettivoPresente = null;
          return const NonIscritto();
        }

        if (!_notificheProgrammate) {
          _notificheProgrammate = true;
          _scheduleNotifiche();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService().handleLaunchNotification();
          });

          _verificaObiettivo(snapshot.data!.uid);
        }

        if (_obiettivoPresente == null) return const _Splash();

        if (_obiettivoPresente == false) {
          return OnboardingObiettivo(
            onCompletato: () {

              if (mounted) setState(() => _obiettivoPresente = true);
            },
          );
        }

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

      if (mounted) setState(() => _obiettivoPresente = true);
    }
  }

  Future<void> _scheduleNotifiche() async {
    final notifService = NotificationService();
    await notifService.scheduleNotificheEventi();
    await notifService.scheduleMotivazionale();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: CircularProgressIndicator(color: colors.accent),
      ),
    );
  }
}