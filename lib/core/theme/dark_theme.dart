import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme.dart';

const AppColors _c = AppColors.dark;

final ColorScheme _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _c.primary,
  onPrimary: _c.onPrimary,
  primaryContainer: _c.secondary,
  onPrimaryContainer: _c.primary,
  secondary: _c.secondary,
  onSecondary: _c.primary,
  secondaryContainer: _c.secondary,
  onSecondaryContainer: _c.primary,
  tertiary: _c.accent,
  onTertiary: _c.onPrimary,
  tertiaryContainer: _c.secondary,
  onTertiaryContainer: _c.accent,
  error: _c.error,
  onError: _c.onPrimary,
  errorContainer: Color.alphaBlend(_c.errorSoft, _c.surface),
  onErrorContainer: _c.textPrimary,
  surface: _c.surface,
  onSurface: _c.textPrimary,
  onSurfaceVariant: _c.textSecondary,
  surfaceDim: _c.background,
  surfaceBright: _c.elevated,
  surfaceContainerLowest: _c.background,
  surfaceContainerLow: _c.backgroundSecondary,
  surfaceContainer: _c.surface,
  surfaceContainerHigh: _c.elevated,
  surfaceContainerHighest: _c.secondary,
  outline: _c.textSecondary,
  outlineVariant: _c.border,
  inverseSurface: _c.elevated,
  onInverseSurface: _c.textPrimary,
  inversePrimary: _c.primary,
  surfaceTint: Colors.transparent,
);

final ThemeData darkTheme = AppTheme.build(
  scheme: _darkScheme,
  colors: _c,
);
