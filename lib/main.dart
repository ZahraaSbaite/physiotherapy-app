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

  // Read the saved theme before the first frame so the app opens in the
  // right mode instead of flashing the wrong one.
  final savedThemeMode = await ThemeStorage().read();

  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(savedThemeMode)],
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
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: AppMotion.medium,
      themeAnimationCurve: Curves.easeInOut,
      // Keeps the status bar and system navigation bar matching the theme on
      // screens that have no AppBar (splash, login, home).
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
