import 'package:flutter/material.dart';

/// The iPhysio color palette.
///
/// Every color used in the UI comes from here. It is registered on the theme
/// as a [ThemeExtension], so widgets read it with `context.appColors` and
/// automatically get the right values in light and dark mode (and a smooth
/// cross-fade when the mode changes).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.elevated,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
  });

  /// Page background.
  final Color background;

  /// A second background level for grouped areas.
  final Color backgroundSecondary;

  /// Cards and containers.
  final Color surface;

  /// Surfaces floating above cards (dialogs, sheets, menus).
  final Color elevated;

  final Color primary;

  /// Text and icons placed on [primary].
  final Color onPrimary;

  /// Soft tint used for selected states, icon tiles and progress tracks.
  final Color secondary;

  final Color accent;
  final Color textPrimary;
  final Color textSecondary;

  /// Borders and dividers.
  final Color border;

  final Color success;
  final Color warning;
  final Color error;

  // Soft tinted backgrounds for status banners and pills.
  Color get successSoft => success.withValues(alpha: 0.14);
  Color get warningSoft => warning.withValues(alpha: 0.16);
  Color get errorSoft => error.withValues(alpha: 0.12);

  static const light = AppColors(
    background: Color(0xFFF7F7F2),
    backgroundSecondary: Color(0xFFF7F7F2),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    primary: Color(0xFF243D35),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFDCE7DF),
    accent: Color(0xFFA7BFAE),
    textPrimary: Color(0xFF252A27),
    textSecondary: Color(0xFF858A85),
    border: Color(0xFFEAECE8),
    success: Color(0xFF548568),
    warning: Color(0xFFD5A65B),
    error: Color(0xFFC76B67),
  );

  static const dark = AppColors(
    background: Color(0xFF121714),
    backgroundSecondary: Color(0xFF171E19),
    surface: Color(0xFF1B231E),
    elevated: Color(0xFF222C25),
    primary: Color(0xFFA8C5B0),
    onPrimary: Color(0xFF121714),
    secondary: Color(0xFF29372F),
    accent: Color(0xFF91AE99),
    textPrimary: Color(0xFFF0F3EF),
    textSecondary: Color(0xFFA0AAA2),
    border: Color(0xFF303A33),
    success: Color(0xFF83B995),
    warning: Color(0xFFE0BA75),
    error: Color(0xFFDE8983),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? backgroundSecondary,
    Color? surface,
    Color? elevated,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColors(
      background: background ?? this.background,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundSecondary:
          Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// The iPhysio palette for the current (light or dark) theme.
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
