import 'api_client.dart';
import 'token_storage.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  Future<AppUser> login(String email, String password) async {
    final data = await _api.post(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    await _storage.write(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> registerTherapist({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // Adjust endpoint path or body keys (e.g., 'name' vs 'fullName' or 'role')
    // if your backend expects different field names.
    final data = await _api.post(
      '/auth/register',
      data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': 'therapist',
      },
    );
    if (data['token'] != null) {
      await _storage.write(data['token'] as String);
    }
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// The user for the saved token, or null if nobody is logged in.
  Future<AppUser?> currentUser() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return null;
    final data = await _api.get('/auth/me');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile(Map<String, dynamic> fields) async {
    final data = await _api.patch('/auth/me', data: fields);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _api.post(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> saveFcmToken(String fcmToken) async {
    await _api.put('/auth/fcm-token', data: {'fcmToken': fcmToken});
  }

  Future<void> logout() async {
    // Best effort: tell the server (it removes the push token),
    // but always clear the phone's token, even without internet.
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.clear();
  }
}
