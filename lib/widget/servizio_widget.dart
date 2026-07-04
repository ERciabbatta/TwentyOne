import 'package:home_widget/home_widget.dart';

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
