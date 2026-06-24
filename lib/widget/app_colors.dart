import 'package:flutter/material.dart';

/// Sistema colori centralizzato dell'app.
///
/// Ogni colore ha un nome semantico (es. `textPrimary`, `surface`) invece
/// che essere usato come valore esadecimale sparso nei widget. Questo
/// permette di avere una versione chiara e una scura mantenendo lo stesso
/// significato in ogni punto dell'app.
///
/// Uso nei widget:
///   final colors = AppColors.of(context);
///   Container(color: colors.surface)
class AppColors {
  final Brightness brightness;

  const AppColors._(this.brightness, {
    required this.background,
    required this.surface,
    required this.surfaceSelected,
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnAccent,
    required this.accent,
    required this.accentGradientEnd,
    required this.success,
    required this.successBackground,
    required this.error,
    required this.errorBackground,
    required this.warning,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceSelected;
  final Color card;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnAccent;
  final Color accent;
  final Color accentGradientEnd;
  final Color success;
  final Color successBackground;
  final Color error;
  final Color errorBackground;
  final Color warning;
  final Color shadow;

  static const AppColors light = AppColors._(
    Brightness.light,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFE8EEF7),
    surfaceSelected: Color(0xFFD0DCF0),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF3A4A5C),
    textSecondary: Color(0xFF8A9BB5),
    textOnAccent: Colors.white,
    accent: Color(0xFF7A9CC6),
    accentGradientEnd: Color(0xFF5B7FA8),
    success: Color(0xFF66BB6A),
    successBackground: Color(0xFFE8F5E9),
    error: Color(0xFFE57373),
    errorBackground: Color(0xFFFFE8E8),
    warning: Color(0xFFFFB74D),
    shadow: Colors.black,
  );

  static const AppColors dark = AppColors._(
    Brightness.dark,
    background: Color(0xFF121821),
    surface: Color(0xFF1E2733),
    surfaceSelected: Color(0xFF2A3A4D),
    card: Color(0xFF1A222C),
    cardBorder: Color(0xFF2E3B4A),
    textPrimary: Color(0xFFE8EEF7),
    textSecondary: Color(0xFF8FA1B8),
    textOnAccent: Colors.white,
    accent: Color(0xFF8FB2DE),
    accentGradientEnd: Color(0xFF6B8FBF),
    success: Color(0xFF7FCB83),
    successBackground: Color(0xFF1E3324),
    error: Color(0xFFEF8A8A),
    errorBackground: Color(0xFF3A2222),
    warning: Color(0xFFFFC373),
    shadow: Colors.black,
  );

  /// Restituisce la palette corretta in base al tema attivo nel context.
  static AppColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
