// Test sulla logica pura dell'app (nessuna dipendenza da Firebase),
// utili a verificare invarianti di base senza dover mockare i servizi
// esterni (auth, Firestore, notifiche locali).

import 'package:flutter_test/flutter_test.dart';
import 'package:twentyone/widget/quotes_data.dart';

void main() {
  group('quotes_data', () {
    test('allQuotes non è vuota', () {
      expect(allQuotes, isNotEmpty);
    });

    test('ogni citazione ha testo, autore e categoria non vuoti', () {
      for (final quote in allQuotes) {
        expect(quote.text.trim(), isNotEmpty);
        expect(quote.author.trim(), isNotEmpty);
        expect(quote.category.trim(), isNotEmpty);
      }
    });

    test('getQuoteOfDay restituisce sempre una citazione presente in allQuotes', () {
      final quote = getQuoteOfDay();
      expect(allQuotes, contains(quote));
    });

    test('getQuoteOfDay è deterministica nello stesso giorno', () {
      final prima = getQuoteOfDay();
      final dopo = getQuoteOfDay();
      expect(prima.text, equals(dopo.text));
    });

    test('le categorie usate nelle citazioni sono un sottoinsieme di quelle note', () {
      const categorieNote = {
        'Disciplina',
        'Abitudini',
        'Mindset',
        'Cambiamento',
        'Coraggio',
        'Gratitudine',
      };
      for (final quote in allQuotes) {
        expect(categorieNote, contains(quote.category),
            reason: 'Categoria sconosciuta: ${quote.category}');
      }
    });
  });
}
