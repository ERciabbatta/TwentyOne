/// Logica pura (nessuna dipendenza da Firebase/plugin) usata per decidere
/// se la streak deve essere azzerata per mancato check-in serale.
///
/// Le regole sono:
/// - Il check-in serale è atteso entro le 22:00.
/// - Se il check-in del giorno corrente non risulta completato entro le
///   02:00 del giorno successivo, la streak va azzerata.
/// - L'azzeramento va eseguito una sola volta per ciclo (niente notifiche
///   o reset duplicati se il check-in è già stato fatto o se il reset è
///   già stato applicato).
class StreakResetLogic {
  const StreakResetLogic._();

  /// Formatta una data come chiave `YYYY-MM-DD`, coerente con il resto
  /// dell'app (vedi `checkin.dart` / `home.dart`).
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Il "giorno di check-in" a cui appartiene un dato istante.
  ///
  /// La finestra di check-in serale va dalle 22:00 fino alle 02:00 del
  /// giorno successivo (deadline di reset). Tra le 00:00 e le 02:59
  /// l'istante fa quindi ancora riferimento al giorno precedente
  /// (è ancora "ieri sera" dal punto di vista del check-in).
  static DateTime giornoDiRiferimento(DateTime now) {
    final oggiMezzanotte = DateTime(now.year, now.month, now.day);
    if (now.hour <= 2) {
      return oggiMezzanotte.subtract(const Duration(days: 1));
    }
    return oggiMezzanotte;
  }

  /// Determina se, dato lo stato attuale, la streak deve essere azzerata
  /// per mancato check-in serale.
  ///
  /// [now] istante di valutazione.
  /// [lastActiveDateKey] valore di `lastActiveDate` salvato su Firestore.
  /// [streak] valore corrente di `streak` salvato su Firestore.
  static bool shouldResetStreak({
    required DateTime now,
    required String? lastActiveDateKey,
    required int streak,
  }) {
    // Niente da azzerare se la streak è già a 0.
    if (streak <= 0) return false;
    if (lastActiveDateKey == null) return true;

    // L'ultimo giorno di cui è scaduto il termine di check-in (ore 02:00 del giorno successivo)
    // si calcola sottraendo 1 giorno e 2 ore all'istante corrente.
    final ultimoScadutoDate = now.subtract(const Duration(days: 1, hours: 2));
    final ultimoScadutoKey = dateKey(ultimoScadutoDate);

    // Se l'ultimo giorno attivo dell'utente è precedente all'ultimo giorno
    // la cui scadenza è passata, la streak deve essere azzerata.
    return lastActiveDateKey.compareTo(ultimoScadutoKey) < 0;
  }

  /// Determina se va inviato un promemoria streak (01:00 / 01:30) dato lo
  /// stato attuale: va inviato solo se il check-in serale del giorno di
  /// riferimento non è ancora stato completato.
  static bool shouldSendReminder({
    required DateTime now,
    required String? lastActiveDateKey,
  }) {
    final giornoAtteso = dateKey(giornoDiRiferimento(now));
    return lastActiveDateKey != giornoAtteso;
  }
}