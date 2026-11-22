import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 20;
}

abstract final class AppRadius {
  static const double input = 12;
  static const double button = 14;
  static const double card = 18;
  static const double dialog = 20;
  static const double sheet = 24;
  static const double fab = 18;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeOutCubic;
}

abstract final class AppTheme {
  static const String fontFamily = 'Manrope';

  static SystemUiOverlayStyle overlayStyle(
    AppColors c,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final iconBrightness =
        isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness:
          isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: c.surface,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  static TextTheme _textTheme(AppColors c) {
    TextStyle style(
      double size,
      FontWeight weight, {
      double height = 1.4,
      double letterSpacing = 0,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? c.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
    }

    return TextTheme(
      displayLarge: style(
        36,
        FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.9,
      ),
      displayMedium: style(
        32,
        FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.7,
      ),
      displaySmall: style(
        30,
        FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.6,
      ),
      headlineLarge: style(
        32,
        FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.6,
      ),
      headlineMedium: style(
        30,
        FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.6,
      ),
      headlineSmall: style(
        26,
        FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.4,
      ),
      titleLarge: style(
        20,
        FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      titleMedium: style(16, FontWeight.w600, height: 1.35),
      titleSmall: style(14, FontWeight.w600, height: 1.35),
      bodyLarge: style(16, FontWeight.w400, height: 1.5),
      bodyMedium: style(14, FontWeight.w400, height: 1.5),
      bodySmall: style(13, FontWeight.w400, color: c.textSecondary),
      labelLarge: style(14, FontWeight.w600, height: 1.3),
      labelMedium: style(13, FontWeight.w500, color: c.textSecondary),
      labelSmall: style(12, FontWeight.w500, color: c.textSecondary),
    );
  }

  static ThemeData build({
    required ColorScheme scheme,
    required AppColors colors,
  }) {
    final c = colors;
    final text = _textTheme(c);
    final brightness = scheme.brightness;

    RoundedRectangleBorder rounded(
      double radius, {
      BorderSide? side,
    }) {
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side ?? BorderSide.none,
      );
    }

    final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
      rounded(AppRadius.button),
    );
    const buttonPadding = WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    );
    final buttonText = WidgetStatePropertyAll<TextStyle?>(
      text.labelLarge?.copyWith(fontSize: 15),
    );

    WidgetStateProperty<Color?> pressOverlay(Color base) {
      return WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return base.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return base.withValues(alpha: 0.08);
        }
        return null;
      });
    }

    final disabledBackground = c.secondary;
    final disabledForeground = c.primary.withValues(alpha: 0.5);

    // ---- Buttons ----
    final filledButton = FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(52),
        ),
        padding: buttonPadding,
        shape: buttonShape,
        elevation: const WidgetStatePropertyAll(0),
        textStyle: buttonText,
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.disabled)
                  ? disabledBackground
                  : c.primary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.disabled)
                  ? disabledForeground
                  : c.onPrimary,
        ),
        overlayColor: pressOverlay(c.onPrimary),
      ),
    );

    final elevatedButton = ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(52),
        ),
        padding: buttonPadding,
        shape: buttonShape,
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: buttonText,
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.disabled)
                  ? c.border
                  : c.secondary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.disabled)
                  ? c.textSecondary
                  : c.primary,
        ),
        overlayColor: pressOverlay(c.primary),
      ),
    );

    final outlinedButton = OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(52),
        ),
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonText,
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.disabled)
                  ? c.textSecondary
                  : c.primary,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color:
                s.contains(WidgetState.disabled)
                    ? c.border
                    : c.accent,
          ),
        ),
        overlayColor: pressOverlay(c.primary),
      ),
    );

    final textButton = TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        shape: WidgetStatePropertyAll<OutlinedBorder>(rounded(12)),
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          text.labelLarge,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.disabled)
                  ? c.textSecondary
                  : c.highlight,
        ),
        overlayColor: pressOverlay(c.highlight),
      ),
    );

    final fab = FloatingActionButtonThemeData(
      backgroundColor: c.highlight,
      foregroundColor: c.onHighlight,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: rounded(AppRadius.fab),
    );

    // ---- Inputs ----
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: c.border),
    );

    TextStyle labelStyle(Set<WidgetState> states) {
      final color =
          states.contains(WidgetState.error)
              ? c.error
              : states.contains(WidgetState.focused)
              ? c.highlight
              : c.textSecondary;
      return text.bodyLarge!.copyWith(color: color);
    }

    final inputDecoration = InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: inputBorder,
      enabledBorder: inputBorder,
      disabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: c.highlight, width: 1.5),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: c.error),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: c.error, width: 1.5),
      ),
      labelStyle: WidgetStateTextStyle.resolveWith(labelStyle),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        labelStyle,
      ),
      hintStyle: text.bodyLarge!.copyWith(color: c.textSecondary),
      helperStyle: text.bodySmall,
      errorStyle: text.bodySmall!.copyWith(color: c.error),
      prefixIconColor: WidgetStateColor.resolveWith(
        (s) =>
            s.contains(WidgetState.focused)
                ? c.highlight
                : c.textSecondary,
      ),
      suffixIconColor: WidgetStateColor.resolveWith(
        (s) =>
            s.contains(WidgetState.focused)
                ? c.highlight
                : c.textSecondary,
      ),
    );

    // ---- Navigation ----
    final navigationBar = NavigationBarThemeData(
      height: 68,
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: c.highlightSoft,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 24,
          color:
              s.contains(WidgetState.selected)
                  ? c.highlight
                  : c.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? c.highlight : c.textSecondary,
        );
      }),
    );

    final tabBar = TabBarThemeData(
      labelColor: c.highlight,
      unselectedLabelColor: c.textSecondary,
      indicatorColor: c.highlight,
      dividerColor: c.border,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );

    final segmentedButton = SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          rounded(AppRadius.input),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: c.border)),
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          text.labelLarge?.copyWith(fontSize: 13),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? c.highlightSoft
                  : c.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? c.highlight
                  : c.textSecondary,
        ),
        overlayColor: pressOverlay(c.highlight),
      ),
    );

    // ---- Toggles ----
    final switchTheme = SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected)
                ? c.onHighlight
                : c.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? c.highlight : c.border,
      ),
      trackOutlineColor: WidgetStatePropertyAll(c.border),
      overlayColor: pressOverlay(c.highlight),
    );

    final checkbox = CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected)
                ? c.highlight
                : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(c.onHighlight),
      side: WidgetStateBorderSide.resolveWith(
        (s) => BorderSide(
          color:
              s.contains(WidgetState.selected)
                  ? c.highlight
                  : c.border,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      overlayColor: pressOverlay(c.highlight),
    );

    final radio = RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? c.highlight : c.border,
      ),
      overlayColor: pressOverlay(c.highlight),
    );

    final slider = SliderThemeData(
      activeTrackColor: c.highlight,
      inactiveTrackColor: c.secondary,
      thumbColor: c.highlight,
      overlayColor: c.highlightSoft,
      valueIndicatorColor: c.highlight,
      valueIndicatorTextStyle: text.labelMedium?.copyWith(
        color: c.onHighlight,
      ),
    );

    // ---- Chip (FIXED: removed invalid selectedLabelStyle) ----
    final chip = ChipThemeData(
      backgroundColor: c.secondary,
      selectedColor: c.highlight,
      side: BorderSide.none,
      shape: rounded(10),
      labelStyle: text.labelMedium?.copyWith(
        color: c.primary,
        fontWeight: FontWeight.w600,
      ),
      checkmarkColor: c.onHighlight,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );

    // ---- Surfaces ----
    final card = CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: rounded(AppRadius.card),
    );

    final dialog = DialogThemeData(
      backgroundColor: c.elevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: rounded(AppRadius.dialog),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: c.textSecondary,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    );

    final bottomSheet = BottomSheetThemeData(
      backgroundColor: c.elevated,
      modalBackgroundColor: c.elevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: c.textSecondary.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    );

    final popupMenu = PopupMenuThemeData(
      color: c.elevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: rounded(
        AppRadius.button,
        side: BorderSide(color: c.border),
      ),
      textStyle: text.bodyMedium,
    );

    final snackBar = SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      actionTextColor: c.highlight,
      elevation: 0,
      shape: rounded(AppRadius.button),
    );

    // ---- ListTile (FIXED: removed invalid selectedIconTheme) ----
    final listTile = ListTileThemeData(
      iconColor: c.textSecondary,
      selectedTileColor: c.highlightSoft,
      textColor: c.textPrimary,
      selectedColor: c.highlight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: rounded(AppRadius.button),
    );

    final progress = ProgressIndicatorThemeData(
      color: c.highlight,
      linearTrackColor: c.secondary,
      linearMinHeight: 6,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      iconTheme: IconThemeData(color: c.textPrimary, size: 24),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.textPrimary),
        systemOverlayStyle: overlayStyle(c, brightness),
      ),
      cardTheme: card,
      dialogTheme: dialog,
      bottomSheetTheme: bottomSheet,
      popupMenuTheme: popupMenu,
      snackBarTheme: snackBar,
      chipTheme: chip,
      listTileTheme: listTile,
      filledButtonTheme: filledButton,
      elevatedButtonTheme: elevatedButton,
      outlinedButtonTheme: outlinedButton,
      textButtonTheme: textButton,
      floatingActionButtonTheme: fab,
      inputDecorationTheme: inputDecoration,
      navigationBarTheme: navigationBar,
      tabBarTheme: tabBar,
      segmentedButtonTheme: segmentedButton,
      switchTheme: switchTheme,
      checkboxTheme: checkbox,
      radioTheme: radio,
      sliderTheme: slider,
      progressIndicatorTheme: progress,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.highlight,
        selectionColor: c.highlightSoftStrong,
        selectionHandleColor: c.highlight,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      extensions: [c],
    );
  }
}
