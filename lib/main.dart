import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/theme_provider.dart';
import 'utils/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Read the saved theme before the first frame.
  final savedThemeMode = await ThemeStorage().read();

  // 2. FALLBACK: If nothing is saved yet, default to Light Mode.
  final defaultThemeMode = savedThemeMode;

  runApp(
    ProviderScope(
      overrides: [
        // 3. Override the initial provider with our guaranteed light-mode default
        initialThemeModeProvider.overrideWithValue(defaultThemeMode),
      ],
      child: const PhysioApp(),
    ),
  );
}

class PhysioApp extends ConsumerWidget {
  const PhysioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'iPhysio',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,

      // This respects the user's choice, but starts with Light as the default
      themeMode: ref.watch(themeModeProvider),

      themeAnimationDuration: AppMotion.medium,
      themeAnimationCurve: Curves.easeInOut,

      // Keeps the status bar and system navigation bar matching the theme
      builder: (context, child) {
        final theme = Theme.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlayStyle(
            theme.extension<AppColors>()!,
            theme.brightness,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
