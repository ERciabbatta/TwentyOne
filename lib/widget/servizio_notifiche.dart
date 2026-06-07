import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:untitled/widget/quotes_data.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _keyEventi = 'notifiche_eventi';
  static const String _keyMotivazionali = 'notifiche_motivazionali';
  static const String _keyCheckIn = 'notifiche_checkin';
  static const int _idCheckIn = 888888;

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

  tz.TZDateTime? _prossimaTriggerTimePerGiorno(String orario, int weekday) {
    final parts = orario.split(':');
    if (parts.length != 2) return null;
    final ore = int.tryParse(parts[0]);
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
      final data = doc.data();
      final inizio = data['inizio'] as String?;
      final testo = data['testo'] as String? ?? 'Hai un evento tra 15 minuti';
      final giorni = List<int>.from(data['giorni'] ?? []);
      if (inizio == null || giorni.isEmpty) continue;

      for (final giorno in giorni) {
        final weekday = giorno + 1;
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
    final random = Random();
    final oreRandom = 4 + random.nextInt(7);
    final trigger = tz.TZDateTime.now(tz.local).add(Duration(hours: oreRandom));
    final quote = allQuotes[random.nextInt(allQuotes.length)];
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
    if (!attivo) return;
    await cancellaCheckIn();

    final now = tz.TZDateTime.now(tz.local);
    var trigger = tz.TZDateTime(tz.local, now.year, now.month, now.day, 22, 0);

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
  }

  Future<void> cancellaCheckIn() async {
    await _plugin.cancel(id: _idCheckIn);
  }

  tz.TZDateTime? _prossimaTriggerTime(String orario) {
    final parts = orario.split(':');
    if (parts.length != 2) return null;
    final ore = int.tryParse(parts[0]);
    final minuti = int.tryParse(parts[1]);
    if (ore == null || minuti == null) return null;
    final now = tz.TZDateTime.now(tz.local);
    var eventoOggi =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, ore, minuti);
    var notificaTime = eventoOggi.subtract(const Duration(minutes: 15));
    if (notificaTime.isBefore(now)) {
      notificaTime = notificaTime.add(const Duration(days: 1));
    }
    return notificaTime;
  }
}