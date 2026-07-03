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
    test('prima delle 02:00 fa riferimento al giorno precedente', () {
      final now = DateTime(2026, 6, 15, 1, 30);
      expect(StreakResetLogic.giornoDiRiferimento(now), DateTime(2026, 6, 14));
    });

    test('dopo le 02:00 fa riferimento al giorno corrente', () {
      final now = DateTime(2026, 6, 15, 10, 0);
      expect(StreakResetLogic.giornoDiRiferimento(now), DateTime(2026, 6, 15));
    });

    test('esattamente alle 02:00 fa ancora riferimento al giorno precedente (deadline inclusa)', () {
      final now = DateTime(2026, 6, 15, 2, 0);
      expect(StreakResetLogic.giornoDiRiferimento(now), DateTime(2026, 6, 14));
    });
  });

  group('StreakResetLogic.shouldResetStreak', () {
    test('non azzera se la streak è già 0', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 2, 0),
        lastActiveDateKey: null,
        streak: 0,
      );
      expect(risultato, isFalse);
    });

    test('non azzera se il check-in di ieri sera è già stato completato', () {
      // Valutazione alle 02:00 del 15: il giorno di riferimento è il 14.
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 2, 0),
        lastActiveDateKey: '2026-06-14',
        streak: 5,
      );
      expect(risultato, isFalse);
    });

    test('azzera se il check-in di ieri sera NON è stato completato', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 2, 0),
        lastActiveDateKey: '2026-06-13',
        streak: 5,
      );
      expect(risultato, isTrue);
    });

    test('azzera se non c\'è mai stato un check-in (lastActiveDate null)', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 2, 0),
        lastActiveDateKey: null,
        streak: 3,
      );
      expect(risultato, isTrue);
    });

    test('valutazione tra 00:00 e 02:00 usa correttamente il giorno precedente', () {
      // Alle 01:45 del 15, il check-in atteso è quello del 14: se è stato
      // fatto, non si azzera anche se "oggi" (15) non è ancora iniziato.
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 1, 45),
        lastActiveDateKey: '2026-06-14',
        streak: 7,
      );
      expect(risultato, isFalse);
    });

    test('non azzera se valutato durante il giorno successivo (es. alle 10:00) e ieri è stato completato', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 10, 0),
        lastActiveDateKey: '2026-06-14',
        streak: 3,
      );
      expect(risultato, isFalse);
    });

    test('non azzera se valutato nel pomeriggio (es. alle 17:45) e ieri è stato completato', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 17, 45),
        lastActiveDateKey: '2026-06-14',
        streak: 3,
      );
      expect(risultato, isFalse);
    });

    test('azzera se valutato durante il giorno successivo (es. alle 10:00) e ieri NON è stato completato', () {
      final risultato = StreakResetLogic.shouldResetStreak(
        now: DateTime(2026, 6, 15, 10, 0),
        lastActiveDateKey: '2026-06-13',
        streak: 3,
      );
      expect(risultato, isTrue);
    });
  });

  group('StreakResetLogic.shouldSendReminder', () {
    test('invia il promemoria se il check-in non è stato completato', () {
      final risultato = StreakResetLogic.shouldSendReminder(
        now: DateTime(2026, 6, 15, 1, 0),
        lastActiveDateKey: '2026-06-13',
      );
      expect(risultato, isTrue);
    });

    test('non invia il promemoria se il check-in è già stato completato', () {
      final risultato = StreakResetLogic.shouldSendReminder(
        now: DateTime(2026, 6, 15, 1, 0),
        lastActiveDateKey: '2026-06-14',
      );
      expect(risultato, isFalse);
    });
  });
}