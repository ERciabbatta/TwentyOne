// Test sulla logica pura di azzeramento streak per check-in serale
// mancato (nessuna dipendenza da Firebase/plugin di notifiche).

import 'package:flutter_test/flutter_test.dart';
import 'package:twentyone/widget/streak_reset_logic.dart';

void main() {
  group('StreakResetLogic.dateKey', () {
    test('formatta la data come YYYY-MM-DD con zero padding', () {
      expect(StreakResetLogic.dateKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(StreakResetLogic.dateKey(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('StreakResetLogic.giornoDiRiferimento', () {
    test('alle 23:30 fa riferimento al giorno corrente', () {
      final now = DateTime(2026, 6, 15, 23, 30);
      expect(StreakResetLogic.giornoDiRiferimento(now), DateTime(2026, 6, 15));
    });

    test('esattamente alle 00:00 fa riferimento al giorno precedente', () {
      final now = DateTime(2026, 6, 15, 0, 0);
      expect(StreakResetLogic.giornoDiRiferimento(now), DateTime(2026, 6, 14));
    });

    test('subito dopo la mezzanotte torna al giorno corrente', () {
      final now = DateTime(2026, 6, 15, 0, 1);
      expect(StreakResetLogic.giornoDiRiferimento(now), DateTime(2026, 6, 15));
    });
  });

  group('StreakResetLogic.shouldResetStreak', () {
    test('non azzera se la streak è già 0', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 0, 0),
        lastActiveDateKey: null,
        streak: 0,
      );
      expect(risultato, isFalse);
    });

    test('non azzera se il check-in in scadenza è già stato completato', () {
      // Valutazione a mezzanotte del 15: il giorno appena scaduto è il 14.
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 0, 0),
        lastActiveDateKey: '2026-06-14',
        streak: 5,
      );
      expect(risultato, isFalse);
    });

    test('azzera se il check-in in scadenza NON è stato completato', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 0, 0),
        lastActiveDateKey: '2026-06-13',
        streak: 5,
      );
      expect(risultato, isTrue);
    });

    test('azzera se non c\'è mai stato un check-in (lastActiveDate null)', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 0, 0),
        lastActiveDateKey: null,
        streak: 3,
      );
      expect(risultato, isTrue);
    });

    test('alle 23:30 non azzera se il giorno precedente risulta completato', () {
      // Alle 23:30 del 15 è ancora presto per valutare il check-in del 15:
      // il giorno scaduto più recente resta il 14.
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 23, 30),
        lastActiveDateKey: '2026-06-14',
        streak: 7,
      );
      expect(risultato, isFalse);
    });

    test('non azzera se valutato durante il giorno successivo e ieri è stato completato', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 10, 0),
        lastActiveDateKey: '2026-06-14',
        streak: 3,
      );
      expect(risultato, isFalse);
    });

    test('non azzera se valutato nel pomeriggio e ieri è stato completato', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 17, 45),
        lastActiveDateKey: '2026-06-14',
        streak: 3,
      );
      expect(risultato, isFalse);
    });

    test('azzera se valutato durante il giorno successivo e ieri NON è stato completato', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 10, 0),
        lastActiveDateKey: '2026-06-13',
        streak: 3,
      );
      expect(risultato, isTrue);
    });
  });

  group('StreakResetLogic.shouldSendReminder', () {
    test('invia il promemoria delle 23:30 se il check-in non è stato completato', () {
      final risultato = StreakResetLogic.shouldSendReminder(
        now: DateTime(2026, 6, 15, 23, 30),
        lastActiveDateKey: '2026-06-13',
      );
      expect(risultato, isTrue);
    });

    test('non invia il promemoria delle 23:30 se il check-in è già stato completato', () {
      final risultato = StreakResetLogic.shouldSendReminder(
        now: DateTime(2026, 6, 15, 23, 30),
        lastActiveDateKey: '2026-06-15',
      );
      expect(risultato, isFalse);
    });

    test('a mezzanotte valuta ancora il check-in del giorno appena concluso', () {
      final risultato = StreakResetLogic.shouldSendReminder(
        now: DateTime(2026, 6, 16, 0, 0),
        lastActiveDateKey: '2026-06-14',
      );
      expect(risultato, isTrue);
    });
  });
}