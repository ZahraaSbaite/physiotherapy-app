class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.medicalNotes,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;

  /// Private notes for the therapist. Only returned when a single patient is loaded.
  final String? medicalNotes;
  final bool isActive;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: (json['_id'] ?? json['id']).toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      medicalNotes: json['medicalNotes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // Empty strings and null clear an optional field on the server (PATCH).
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'medicalNotes': medicalNotes ?? '',
      };
}
