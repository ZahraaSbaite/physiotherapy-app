class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.condition,
    this.notes,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? condition;
  final String? notes;
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
      condition: json['condition'] as String?,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
        if (condition != null && condition!.isNotEmpty) 'condition': condition,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
