import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme.dart';

const AppColors _c = AppColors.light;

final ColorScheme _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: _c.primary,
  onPrimary: _c.onPrimary,
  primaryContainer: _c.secondary,
  onPrimaryContainer: _c.primary,
  secondary: _c.secondary,
  onSecondary: _c.primary,
  secondaryContainer: _c.secondary,
  onSecondaryContainer: _c.primary,
  tertiary: _c.accent,
  onTertiary: _c.textPrimary,
  tertiaryContainer: _c.accent,
  onTertiaryContainer: _c.textPrimary,
  error: _c.error,
  onError: _c.onPrimary,
  errorContainer: Color.alphaBlend(_c.errorSoft, _c.surface),
  onErrorContainer: _c.textPrimary,
  surface: _c.surface,
  onSurface: _c.textPrimary,
  onSurfaceVariant: _c.textSecondary,
  surfaceDim: _c.background,
  surfaceBright: _c.surface,
  surfaceContainerLowest: _c.surface,
  surfaceContainerLow: _c.background,
  surfaceContainer: _c.surface,
  surfaceContainerHigh: _c.elevated,
  surfaceContainerHighest: _c.secondary,
  outline: _c.textSecondary,
  outlineVariant: _c.border,
  inverseSurface: _c.primary,
  onInverseSurface: _c.background,
  inversePrimary: _c.accent,
  surfaceTint: Colors.transparent,
);

final ThemeData lightTheme = AppTheme.build(
  scheme: _lightScheme,
  colors: _c,
);
