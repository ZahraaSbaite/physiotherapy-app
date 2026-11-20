class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.isActive,
    this.phone,
    this.adminId,
    this.dateOfBirth,
    this.gender,
    this.profileImageUrl,
    this.defaultCurrency,
  });

  final String id;
  final String role; // 'admin' or 'patient'
  final String name;
  final String email;
  final bool isActive;
  final String? phone;
  final String? adminId; // patients only
  final String? dateOfBirth;
  final String? gender;
  final String? profileImageUrl;
  final String? defaultCurrency; // admins only

  bool get isAdmin => role == 'admin';
  bool get isPatient => role == 'patient';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] as String,
      role: json['role'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      phone: json['phone'] as String?,
      adminId: json['adminId'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      defaultCurrency: json['defaultCurrency'] as String?,
    );
  }
}
