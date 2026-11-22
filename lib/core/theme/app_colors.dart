import 'package:flutter/material.dart';

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
    required this.highlight,
    required this.highlightPressed,
    required this.onHighlight,
    required this.hero,
    required this.onHero,
  });

  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color elevated;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color highlight;
  final Color highlightPressed;
  final Color onHighlight;
  final Color hero;
  final Color onHero;

  Color get successSoft => success.withValues(alpha: 0.14);
  Color get warningSoft => warning.withValues(alpha: 0.16);
  Color get errorSoft => error.withValues(alpha: 0.12);
  Color get highlightSoft => highlight.withValues(alpha: 0.12);
  Color get highlightSoftStrong => highlight.withValues(alpha: 0.25);

  static const light = AppColors(
    background: Color(0xFFF0F2EC),
    backgroundSecondary: Color(0xFFE7EBE3),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    primary: Color(0xFF1E4638),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFDCE7DF),
    accent: Color(0xFFA7BFAE),
    textPrimary: Color(0xFF1F2521),
    textSecondary: Color(0xFF5C645E),
    border: Color(0xFFCFD6CC),
    success: Color(0xFF3E7A59),
    warning: Color(0xFFB8832F),
    error: Color(0xFFB44A44),
    highlight: Color(0xFFE07A5F), // Terracotta "Pop"
    highlightPressed: Color(
      0xFFC8623F,
    ), // Deeper terracotta for presses
    onHighlight: Color(0xFFFFFFFF),
    hero: Color(0xFF1E4638),
    onHero: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    background: Color(0xFF111613),
    backgroundSecondary: Color(0xFF151B17),
    surface: Color(0xFF1A221D),
    elevated: Color(0xFF222C25),
    primary: Color(0xFFA8C5B0),
    onPrimary: Color(0xFF111613),
    secondary: Color(0xFF29372F),
    accent: Color(0xFF91AE99),
    textPrimary: Color(0xFFF0F3EF),
    textSecondary: Color(0xFFA9B3AB),
    border: Color(0xFF36413A),
    success: Color(0xFF83B995),
    warning: Color(0xFFE0BA75),
    error: Color(0xFFE58F89),
    highlight: Color(0xFFE89F71), // Warm terracotta for dark mode
    highlightPressed: Color(0xFFD07C4E),
    onHighlight: Color(0xFF111613),
    hero: Color(0xFF24382D),
    onHero: Color(0xFFF0F3EF),
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
    Color? highlight,
    Color? highlightPressed,
    Color? onHighlight,
    Color? hero,
    Color? onHero,
  }) {
    return AppColors(
      background: background ?? this.background,
      backgroundSecondary:
          backgroundSecondary ?? this.backgroundSecondary,
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
      highlight: highlight ?? this.highlight,
      highlightPressed: highlightPressed ?? this.highlightPressed,
      onHighlight: onHighlight ?? this.onHighlight,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundSecondary:
          Color.lerp(
            backgroundSecondary,
            other.backgroundSecondary,
            t,
          )!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      highlightPressed:
          Color.lerp(highlightPressed, other.highlightPressed, t)!,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
