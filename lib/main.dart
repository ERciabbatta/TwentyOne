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

/// Provider globale per gestire e notificare i cambiamenti di tema dell'applicazione.
final themeProvider = ThemeProvider();

/// Funzione di ingresso principale (entrypoint) dell'applicazione.
/// Inizializza il binding di Flutter, Firebase, carica le preferenze del tema,
/// inizializza il servizio di notifiche locali e infine avvia l'app in un contesto protetto (runZonedGuarded)
/// per catturare eventuali errori non gestiti.
void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Inizializza Firebase con le opzioni specifiche della piattaforma corrente
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Carica le preferenze di tema precedentemente salvate dall'utente
    await themeProvider.caricaPreferenza();

    // Inizializza e richiede i permessi per il servizio notifiche
    final notifService = NotificationService();
    await notifService.init();
    await notifService.richiediPermessi();

    runApp(const MyApp());
  }, (error, stack) {
    // Schermata di fallback in caso di errore critico all'avvio dell'applicazione
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

/// Widget principale dell'applicazione che configura il tema globale,
/// le rotte di navigazione e definisce la schermata iniziale (AuthGate).
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'TwentyOne',
          navigatorKey: NotificationService.navigatorKey, // Chiave di navigazione per le notifiche tap
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

/// Widget che funge da "guardia di accesso" (AuthGate).
/// Ascolta lo stato di autenticazione dell'utente e reindirizza a:
/// - [NonIscritto] se l'utente non è autenticato.
/// - [OnboardingObiettivo] se l'utente è autenticato ma non ha ancora inserito un obiettivo.
/// - [MyBottomBar] se l'utente è autenticato ed ha già impostato un obiettivo.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Flag per evitare di pianificare le notifiche più volte nella stessa sessione
  bool _notificheProgrammate = false;

  // Stato sulla presenza dell'obiettivo: null = caricamento, false = mancante, true = impostato
  bool? _obiettivoPresente;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostra lo splash screen durante l'attesa del primo evento di auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        // Utente non autenticato
        if (snapshot.data == null) {
          _notificheProgrammate = false;
          _obiettivoPresente = null;
          return const NonIscritto();
        }

        // Utente autenticato: esegue l'inizializzazione iniziale per la sessione
        if (!_notificheProgrammate) {
          _notificheProgrammate = true;
          _scheduleNotifiche();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Gestisce l'avvio dell'app da una notifica cliccata
            NotificationService().handleLaunchNotification();
          });
          // Controlla se la streak è da resettare per inattività
          NotificationService().valutaResetStreakSeNecessario();

          // Verifica se l'utente ha configurato un obiettivo su Firestore
          _verificaObiettivo(snapshot.data!.uid);
        }

        // In attesa del completamento del controllo sull'obiettivo
        if (_obiettivoPresente == null) return const _Splash();

        // Se l'obiettivo non è configurato, forza la schermata di Onboarding Obiettivo
        if (_obiettivoPresente == false) {
          return OnboardingObiettivo(
            onCompletato: () {
              if (mounted) setState(() => _obiettivoPresente = true);
            },
          );
        }

        // Flusso standard dell'applicazione con barra di navigazione
        return const MyBottomBar();
      },
    );
  }

  /// Verifica se nel documento utente su Firestore è presente il campo 'obiettivo'.
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
      // In caso di errore di rete, fallback ottimistico a true per evitare blocco
      if (mounted) setState(() => _obiettivoPresente = true);
    }
  }

  /// Schedula le notifiche pianificate locali (eventi, motivazionali, check-in).
  Future<void> _scheduleNotifiche() async {
    final notifService = NotificationService();
    await notifService.scheduleNotificheEventi();
    await notifService.scheduleMotivazionale();
    await notifService.scheduleCheckIn();
  }
}

/// Widget interno per la schermata di caricamento/Splash.
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