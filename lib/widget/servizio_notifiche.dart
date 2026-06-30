import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:twentyone/widget/quotes_data.dart';
import 'package:twentyone/widget/streak_reset_logic.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _keyEventi          = 'notifiche_eventi';
  static const String _keyMotivazionali   = 'notifiche_motivazionali';
  static const String _keyCheckIn         = 'notifiche_checkin';
  static const String _keyStreakReminder  = 'notifiche_streak_reminder';
  static const int    _idCheckIn          = 888888;
  static const int    _idStreakReminder   = 777777;

  // Promemoria di scadenza per il check-in serale (entro le 02:00, vedi
  // StreakResetLogic) e notifica di avvenuto azzeramento della streak.
  static const int    _idStreakDeadline1h   = 666661; // 01:00
  static const int    _idStreakDeadline30m  = 666662; // 01:30
  static const int    _idStreakResetAvvenuto = 666663; // 02:00
  // Chiave usata per evitare di rivalutare/azzerare due volte la streak
  // per lo stesso "giorno di riferimento" (guard anti-duplicati).
  static const String _keyUltimoGiornoValutatoReset =
      'streak_reset_ultimo_giorno_valutato';

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'checkin_channel',
      'Check-in giornaliero',
      description: 'Promemoria serale per il check-in',
      importance: Importance.high,
    ));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'eventi_channel',
      'Notifiche eventi',
      description: 'Promemoria 15 minuti prima degli eventi',
      importance: Importance.high,
    ));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'motivazionali_channel',
      'Frasi motivazionali',
      description: 'Frasi di ispirazione quotidiana',
      importance: Importance.defaultImportance,
    ));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'streak_reminder_channel',
      'Recupero streak',
      description: 'Avviso serale se non hai ancora fatto il check-in',
      importance: Importance.high,
    ));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'streak_deadline_channel',
      'Scadenza streak',
      description: 'Promemoria e avviso di azzeramento streak per check-in mancato',
      importance: Importance.high,
    ));
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.id == _idCheckIn ||
        response.id == _idStreakReminder ||
        response.id == _idStreakDeadline1h ||
        response.id == _idStreakDeadline30m) {
      _navigateToCheckIn();
    }
  }

  void _navigateToCheckIn() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).pushNamed('/checkin');
  }

  Future<void> handleLaunchNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details != null &&
        details.didNotificationLaunchApp &&
        (details.notificationResponse?.id == _idCheckIn ||
            details.notificationResponse?.id == _idStreakReminder ||
            details.notificationResponse?.id == _idStreakDeadline1h ||
            details.notificationResponse?.id == _idStreakDeadline30m)) {
      _navigateToCheckIn();
    }
  }

  Future<void> richiediPermessi() async {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<bool> getEventiAttivi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEventi) ?? true;
  }

  Future<bool> getMotivazionaliAttive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMotivazionali) ?? true;
  }

  Future<bool> getCheckInAttivo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCheckIn) ?? true;
  }

  Future<bool> getStreakReminderAttivo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStreakReminder) ?? true;
  }

  Future<void> setEventiAttivi(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEventi, value);
    if (value) {
      await scheduleNotificheEventi();
    } else {
      await cancellaNotificheEventi();
    }
  }

  Future<void> setMotivazionaliAttive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMotivazionali, value);
    if (value) {
      await scheduleMotivazionale();
    } else {
      await cancellaMotivazionali();
    }
  }

  Future<void> setCheckInAttivo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCheckIn, value);
    if (value) {
      await scheduleCheckIn();
    } else {
      await cancellaCheckIn();
    }
  }

  Future<void> setStreakReminderAttivo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreakReminder, value);
    if (value) {
      await scheduleStreakReminder();
    } else {
      await cancellaStreakReminder();
    }
  }

  tz.TZDateTime? _prossimaTriggerTimePerGiorno(String orario, int weekday) {
    final parts = orario.split(':');
    if (parts.length != 2) return null;
    final ore    = int.tryParse(parts[0]);
    final minuti = int.tryParse(parts[1]);
    if (ore == null || minuti == null) return null;

    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(tz.local, now.year, now.month, now.day, ore, minuti)
        .subtract(const Duration(minutes: 15));

    while (candidate.weekday != weekday || candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  Future<void> scheduleNotificheEventi() async {
    final attive = await getEventiAttivi();
    if (!attive) return;
    await cancellaNotificheEventi();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .collection('note')
        .get();

    for (final doc in snapshot.docs) {
      final data   = doc.data();
      final inizio = data['inizio'] as String?;
      final testo  = data['testo'] as String? ?? 'Hai un evento tra 15 minuti';
      final giorni = List<int>.from(data['giorni'] ?? []);
      if (inizio == null || giorni.isEmpty) continue;

      for (final giorno in giorni) {
        final weekday      = giorno + 1;
        final notificaTime = _prossimaTriggerTimePerGiorno(inizio, weekday);
        if (notificaTime == null) continue;

        final id = (doc.id.hashCode.abs() + giorno * 100003) % 100000;

        await _plugin.zonedSchedule(
          id: id,
          title: '⏰ Tra 15 minuti',
          body: testo,
          scheduledDate: notificaTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'eventi_channel',
              'Notifiche eventi',
              channelDescription: 'Promemoria 15 minuti prima degli eventi',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  Future<void> cancellaNotificheEventi() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .collection('note')
        .get();
    for (final doc in snapshot.docs) {
      for (int giorno = 0; giorno < 7; giorno++) {
        final id = (doc.id.hashCode.abs() + giorno * 100003) % 100000;
        await _plugin.cancel(id: id);
      }
    }
  }

  Future<void> scheduleMotivazionale() async {
    final attive = await getMotivazionaliAttive();
    if (!attive) return;
    await cancellaMotivazionali();

    final random    = Random();
    final oreRandom = 4 + random.nextInt(7);
    final trigger   = tz.TZDateTime.now(tz.local).add(Duration(hours: oreRandom));
    final quote     = allQuotes[random.nextInt(allQuotes.length)];

    await _plugin.zonedSchedule(
      id: 999999,
      title: '💪 ${quote.author}',
      body: quote.text,
      scheduledDate: trigger,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivazionali_channel',
          'Frasi motivazionali',
          channelDescription: 'Frasi di ispirazione quotidiana',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancellaMotivazionali() async {
    await _plugin.cancel(id: 999999);
  }

  Future<void> scheduleCheckIn() async {
    final attivo = await getCheckInAttivo();
    if (!attivo) {
      await cancellaCheckIn();
      await cancellaStreakDeadline();
      return;
    }
    await cancellaCheckIn();

    final now     = tz.TZDateTime.now(tz.local);
    var trigger   = tz.TZDateTime(tz.local, now.year, now.month, now.day, 22, 0);

    if (!trigger.isAfter(now.add(const Duration(minutes: 1)))) {
      trigger = trigger.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _idCheckIn,
      title: '🌙 Check-in serale',
      body: 'Come è andata oggi? Fai il tuo check-in!',
      scheduledDate: trigger,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin_channel',
          'Check-in giornaliero',
          channelDescription: 'Promemoria serale per il check-in',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await scheduleStreakDeadline();
  }

  Future<void> cancellaCheckIn() async {
    await _plugin.cancel(id: _idCheckIn);
    await cancellaStreakDeadline();
  }

  Future<void> scheduleStreakReminder() async {
    final attivo = await getStreakReminderAttivo();
    if (!attivo) return;
    await cancellaStreakReminder();

    final now   = tz.TZDateTime.now(tz.local);
    var trigger = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 30);

    if (!trigger.isAfter(now.add(const Duration(minutes: 1)))) {
      trigger = trigger.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _idStreakReminder,
      title: '🔥 Non perdere la streak!',
      body: 'Non hai ancora fatto il check-in di oggi. Mantieni la tua serie!',
      scheduledDate: trigger,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder_channel',
          'Recupero streak',
          channelDescription: 'Avviso serale se non hai ancora fatto il check-in',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancellaStreakReminder() async {
    await _plugin.cancel(id: _idStreakReminder);
  }

  // ---------------------------------------------------------------------
  // Promemoria di scadenza check-in serale (01:00 / 01:30) + azzeramento
  // streak e relativa notifica alle 02:00.
  //
  // Il check-in serale è atteso entro le 22:00. Se non viene completato
  // entro le 02:00 del giorno successivo, la streak viene azzerata.
  // ---------------------------------------------------------------------

  /// Programma i due promemoria (01:00 e 01:30) e la valutazione del
  /// reset alle 02:00. Va richiamato ogni sera dopo le 22:00 (es. quando
  /// scatta `scheduleCheckIn`) così da coprire sempre la prossima notte.
  Future<void> scheduleStreakDeadline() async {
    final attivo = await getCheckInAttivo();
    if (!attivo) {
      await cancellaStreakDeadline();
      return;
    }
    await cancellaStreakDeadline();

    final now = tz.TZDateTime.now(tz.local);

    // Le notifiche fanno riferimento alla prossima occorrenza delle 01:00
    // e 01:30: se l'orario è già passato oggi, slittano a domani.
    final trigger1h  = _prossimoOrarioOggiODomani(now, 1, 0);
    final trigger30m = _prossimoOrarioOggiODomani(now, 1, 30);

    await _plugin.zonedSchedule(
      id: _idStreakDeadline1h,
      title: '🔥 Streak a rischio',
      body: 'Manca un\'ora: se non fai il check-in entro le 02:00 la streak si azzera.',
      scheduledDate: trigger1h,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_deadline_channel',
          'Scadenza streak',
          channelDescription:
          'Promemoria e avviso di azzeramento streak per check-in mancato',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _plugin.zonedSchedule(
      id: _idStreakDeadline30m,
      title: '🔥 Ultima chiamata',
      body: 'Mancano 30 minuti: se non fai il check-in entro le 02:00 la streak si azzera.',
      scheduledDate: trigger30m,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_deadline_channel',
          'Scadenza streak',
          channelDescription:
          'Promemoria e avviso di azzeramento streak per check-in mancato',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // La notifica di "streak azzerata" non viene programmata in anticipo:
    // dipende dall'esito reale del check-in, quindi viene mostrata solo
    // quando `valutaResetStreakSeNecessario` accerta che il reset è
    // effettivamente avvenuto (vedi sotto).
  }

  Future<void> cancellaStreakDeadline() async {
    await _plugin.cancel(id: _idStreakDeadline1h);
    await _plugin.cancel(id: _idStreakDeadline30m);
    await _plugin.cancel(id: _idStreakResetAvvenuto);
  }

  tz.TZDateTime _prossimoOrarioOggiODomani(tz.TZDateTime now, int ora, int minuto) {
    var candidate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, ora, minuto);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// Valuta se la streak va azzerata per mancato check-in serale e, in tal
  /// caso, azzera la streak su Firestore e invia la notifica di avvenuto
  /// reset. Va chiamato all'avvio dell'app e, idealmente, intorno alle
  /// 02:00 (es. tramite un richiamo periodico/al risveglio dell'app).
  ///
  /// Guard conditions:
  /// - non fa nulla se il check-in del giorno di riferimento è già stato
  ///   completato;
  /// - non invia la notifica di reset se il reset non è effettivamente
  ///   avvenuto;
  /// - non rivaluta/azzera due volte lo stesso "giorno di riferimento"
  ///   (evita reset o notifiche duplicate in caso di richiami multipli,
  ///   es. ad ogni riavvio dell'app nella stessa notte).
  Future<void> valutaResetStreakSeNecessario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = tz.TZDateTime.now(tz.local);
    // Valuta solo dopo le 02:59: fino alle 02:59 siamo ancora nella
    // finestra della sera precedente (deadline alle 02:00 incluse).
    if (now.hour < 3) return;

    final giornoRiferimento = StreakResetLogic.giornoDiRiferimento(now);
    final chiaveGiorno = StreakResetLogic.dateKey(giornoRiferimento);

    final prefs = await SharedPreferences.getInstance();
    final ultimoGiornoValutato = prefs.getString(_keyUltimoGiornoValutatoReset);
    if (ultimoGiornoValutato == chiaveGiorno) {
      // Già valutato (ed eventualmente azzerato) per questo giorno:
      // evita di rieseguire il reset o reinviare la notifica.
      return;
    }

    final userDoc =
    FirebaseFirestore.instance.collection('utenti').doc(user.uid);
    final snapshot = await userDoc.get();
    final data = snapshot.data();
    final lastActiveDate = data?['lastActiveDate'] as String?;
    final streak = data?['streak'] as int? ?? 0;

    // Segna il giorno come valutato prima di procedere, così eventuali
    // chiamate concorrenti/successive nello stesso giorno non rieseguono
    // il reset (guard anti-duplicati).
    await prefs.setString(_keyUltimoGiornoValutatoReset, chiaveGiorno);

    final daAzzerare = StreakResetLogic.shouldResetStreak(
      now: now,
      lastActiveDateKey: lastActiveDate,
      streak: streak,
    );

    if (!daAzzerare) return;

    await userDoc.set({'streak': 0}, SetOptions(merge: true));

    await _plugin.show(
      id: _idStreakResetAvvenuto,
      title: '💔 Streak azzerata',
      body: 'Non hai completato il check-in serale entro le 02:00: la tua streak è stata azzerata.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_deadline_channel',
          'Scadenza streak',
          channelDescription:
          'Promemoria e avviso di azzeramento streak per check-in mancato',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}