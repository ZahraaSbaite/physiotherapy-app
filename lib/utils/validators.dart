class Validators {
  // Same rule as the backend
  static final _emailRegex = RegExp(r'^\S+@\S+\.\S+$');

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your email';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  // At login we only check that something was typed.
  // The server decides whether the password is right.
  static String? passwordRequired(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    return null;
  }

  static String? name(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter your name';
    return null;
  }

  // Same minimum as the backend
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a new password';
    if (v.length < 8) return 'At least 8 characters';
    return null;
  }
}
