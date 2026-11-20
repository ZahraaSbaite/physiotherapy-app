enum AppointmentStatus {
  scheduled('scheduled', 'Scheduled'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  noShow('no_show', 'No show');

  const AppointmentStatus(this.api, this.label);
  final String api;
  final String label;

  static AppointmentStatus parse(String? v) => values.firstWhere(
        (s) => s.api == v,
        orElse: () => AppointmentStatus.scheduled,
      );
}

enum PaymentStatus {
  unpaid('unpaid', 'Unpaid'),
  paid('paid', 'Paid');

  const PaymentStatus(this.api, this.label);
  final String api;
  final String label;

  static PaymentStatus parse(String? v) => values.firstWhere(
        (s) => s.api == v,
        orElse: () => PaymentStatus.unpaid,
      );
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.start,
    this.durationMinutes = 60,
    this.status = AppointmentStatus.scheduled,
    this.notes,
    this.paymentStatus = PaymentStatus.unpaid,
    this.amount,
  });

  final String id;
  final String patientId;
  final String patientName;
  final DateTime start;
  final int durationMinutes;
  final AppointmentStatus status;
  final String? notes;
  final PaymentStatus paymentStatus;
  final double? amount;

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  factory Appointment.fromJson(Map<String, dynamic> j) {
    final p = j['patient'];
    return Appointment(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      patientId: p is Map
          ? (p['_id'] ?? p['id'] ?? '').toString()
          : (j['patientId'] ?? p ?? '').toString(),
      patientName:
          (p is Map ? p['name'] : j['patientName'] ?? '').toString(),
      start: DateTime.parse(j['start'].toString()).toLocal(),
      durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 60,
      status: AppointmentStatus.parse(j['status'] as String?),
      notes: j['notes'] as String?,
      paymentStatus: PaymentStatus.parse(j['paymentStatus'] as String?),
      amount: (j['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'start': start.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        'notes': notes ?? '',
        'status': status.api,
        'paymentStatus': paymentStatus.api,
        if (amount != null) 'amount': amount,
      };
}
