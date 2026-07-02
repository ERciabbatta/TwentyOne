import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestisce la preferenza di tema dell'utente (chiaro / scuro / sistema)
/// e la persiste localmente cosi' resta impostata tra un avvio e l'altro.
///
/// Uso:
///   final themeProvider = ThemeProvider();
///   await themeProvider.caricaPreferenza(); // da chiamare prima di runApp
///   ...
///   ListenableBuilder(
///     listenable: themeProvider,
///     builder: (context, _) => MaterialApp(themeMode: themeProvider.themeMode, ...),
///   )
class ThemeProvider extends ChangeNotifier {
  /// Chiave SharedPreferences sotto cui è salvata la preferenza di tema.
  static const _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  /// Modalità di tema attualmente attiva (chiaro/scuro/sistema).
  ThemeMode get themeMode => _themeMode;

  /// `true` se la modalità attiva è quella scura.
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Carica la preferenza di tema salvata in precedenza (default:
  /// chiaro se non è mai stata impostata) e notifica gli ascoltatori.
  /// Va chiamato prima di `runApp`.
  Future<void> caricaPreferenza() async {
    final prefs = await SharedPreferences.getInstance();
    final salvato = prefs.getString(_key);
    switch (salvato) {
      case 'light':
        _themeMode = ThemeMode.light;
      case 'dark':
        _themeMode = ThemeMode.dark;
      default:
        _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Imposta una nuova modalità di tema, notifica gli ascoltatori (che
  /// aggiornano subito la UI) e persiste la scelta su SharedPreferences.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_key, value);
  }

  /// Comodo per un semplice toggle chiaro/scuro (ignora "system").
  Future<void> toggle() async {
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Istanza globale condivisa da tutta l'app: main.dart la usa per costruire
/// il MaterialApp, le pagine (es. Profilo) la usano per il toggle nelle
/// impostazioni. Tenerla qui invece che in main.dart evita un import
/// circolare tra main.dart e le pagine che vogliono leggerla/modificarla.
final themeProvider = ThemeProvider();
