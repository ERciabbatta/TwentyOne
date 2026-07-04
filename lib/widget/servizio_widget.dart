import 'dart:io' show Platform;
import 'package:home_widget/home_widget.dart';

/// Servizio per la gestione e l'aggiornamento del Widget della Home Screen.
class ServizioWidget {
  const ServizioWidget._();

  /// Salva la streak corrente e i giorni rimanenti e richiede l'aggiornamento
  /// del widget nativo (Android/iOS).
  ///
  /// Nota: su iOS la funzionalità di widget è limitata; il pacchetto
  /// `home_widget` richiede una configurazione nativa aggiuntiva non fornita
  /// in questo progetto. Pertanto, su iOS il metodo non tenta di aggiornare il
  /// widget, evitando errori runtime.
  static Future<void> aggiornaWidget({
    required int streak,
    required int giorniRimanenti,
  }) async {
    try {
      if (Platform.isAndroid) {
        await HomeWidget.saveWidgetData<String>('streak', streak.toString());
        await HomeWidget.saveWidgetData<String>('rimanenti', giorniRimanenti.toString());
        await HomeWidget.updateWidget(
          name: 'TwentyOneWidgetProvider',
          androidName: 'TwentyOneWidgetProvider',
        );
      } else {
        // iOS non supportato: eventuale log o azione alternativa
        // debugPrint('Widget update skipped on iOS (not supported)');
      }
    } catch (e) {
      // Silenzioso in produzione
    }
  }
}

/// Servizio per la gestione e l'aggiornamento del Widget della Home Screen.
class ServizioWidget {
  const ServizioWidget._();

  /// Salva la streak corrente e i giorni rimanenti e richiede l'aggiornamento
  /// del widget nativo (Android/iOS).
  static Future<void> aggiornaWidget({
    required int streak,
    required int giorniRimanenti,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('streak', streak.toString());
      await HomeWidget.saveWidgetData<String>('rimanenti', giorniRimanenti.toString());
      await HomeWidget.updateWidget(
        name: 'TwentyOneWidgetProvider',
        androidName: 'TwentyOneWidgetProvider',
      );
    } catch (e) {
      // Silenzioso in produzione
    }
  }
}
