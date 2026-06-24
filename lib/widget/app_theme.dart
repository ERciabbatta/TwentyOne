import 'package:flutter/material.dart';
import 'package:twentyone/widget/app_colors.dart';

/// Costruisce i ThemeData Material a partire da AppColors, cosi' i widget
/// che usano Theme.of(context) (es. AppBar, Scaffold di default, Switch)
/// seguono automaticamente la palette corretta.
class AppTheme {
  static ThemeData get light => _build(AppColors.light);
  static ThemeData get dark => _build(AppColors.dark);

  static ThemeData _build(AppColors colors) {
    return ThemeData(
      brightness: colors.brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: colors.brightness,
        primary: colors.accent,
        onPrimary: colors.textOnAccent,
        secondary: colors.accent,
        onSecondary: colors.textOnAccent,
        error: colors.error,
        onError: colors.textOnAccent,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : null,
        ),
      ),
      useMaterial3: true,
    );
  }
}
