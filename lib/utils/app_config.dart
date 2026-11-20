import 'package:flutter/foundation.dart';

class AppConfig {
  // Optional override: flutter run --dart-define=API_URL=http://192.168.1.20:5000/api
  static const String _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // The Android emulator reaches your computer through 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }
}
