import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/theme_provider.dart';
import 'utils/app_router.dart';

final FlutterLocalNotificationsPlugin
flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _setupNotifications() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(
    tz.getLocation('Asia/Beirut'),
  ); // adjust to your timezone

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (
      NotificationResponse response,
    ) {
      // Optional: handle tap on notification to open specific appointment
    },
  );

  // Request notification permission on Android 13+ and iOS
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _setupNotifications();

  final savedThemeMode = await ThemeStorage().read();
  final defaultThemeMode = savedThemeMode ?? ThemeMode.light;

  runApp(
    ProviderScope(
      overrides: [
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
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: AppMotion.medium,
      themeAnimationCurve: Curves.easeInOut,
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
