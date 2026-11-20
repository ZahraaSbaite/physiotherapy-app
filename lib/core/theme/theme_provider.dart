import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Saves the chosen theme mode on the device.
///
/// Uses `flutter_secure_storage`, which the app already depends on for the
/// login token, so no extra package is needed.
class ThemeStorage {
  ThemeStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'theme_mode';
  final FlutterSecureStorage _storage;

  /// Returns the saved mode, or [ThemeMode.system] if nothing valid is saved.
  Future<ThemeMode> read() async {
    try {
      final value = await _storage.read(key: _key);
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> write(ThemeMode mode) async {
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {
      // The choice still applies for this session if saving fails.
    }
  }
}

final themeStorageProvider = Provider<ThemeStorage>((ref) => ThemeStorage());

/// The mode that was saved at the previous launch.
///
/// `main()` reads it before the first frame and overrides this provider, so
/// the app opens in the right theme without a flash of the wrong one.
final initialThemeModeProvider = Provider<ThemeMode>(
  (ref) => ThemeMode.system,
);

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  /// Applies the mode right away, then saves it.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref.read(themeStorageProvider).write(mode);
  }
}
