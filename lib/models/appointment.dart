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
  partial('partial', 'Partly paid'),
  paid('paid', 'Paid');

  const PaymentStatus(this.api, this.label);
  final String api;
  final String label;

  static PaymentStatus parse(String? v) => values.firstWhere(
        (s) => s.api == v,
        orElse: () => PaymentStatus.unpaid,
      );
}

enum PaymentMethod {
  cash('cash', 'Cash'),
  card('card', 'Card'),
  transfer('transfer', 'Bank transfer'),
  other('other', 'Other');

  const PaymentMethod(this.api, this.label);
  final String api;
  final String label;

  static PaymentMethod? parse(String? v) {
    for (final m in values) {
      if (m.api == v) return m;
    }
    return null;
  }
}

/// The optional payment of an appointment (the backend's `payment` object).
class Payment {
  const Payment({
    this.status = PaymentStatus.unpaid,
    this.amount,
    this.currency = 'USD',
    this.method,
    this.paidAmount = 0,
    this.note,
  });

  final PaymentStatus status;
  final double? amount;
  final String currency;
  final PaymentMethod? method;
  final double paidAmount;
  final String? note;

  /// e.g. "Partly paid · 20.00 of 50.00 USD"
  String get summary {
    if (amount == null) return status.label;
    final total = amount!.toStringAsFixed(2);
    if (status == PaymentStatus.partial) {
      return '${status.label} · ${paidAmount.toStringAsFixed(2)} of $total $currency';
    }
    return '${status.label} · $total $currency';
  }

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        status: PaymentStatus.parse(j['status'] as String?),
        amount: (j['amount'] as num?)?.toDouble(),
        currency: (j['currency'] as String?) ?? 'USD',
        method: PaymentMethod.parse(j['method'] as String?),
        paidAmount: (j['paidAmount'] as num?)?.toDouble() ?? 0,
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'status': status.api,
        'amount': amount,
        'currency': currency,
        'method': method?.api,
        if (status == PaymentStatus.partial) 'paidAmount': paidAmount,
        'note': note ?? '',
      };
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.start,
    required this.end,
    this.title,
    this.location,
    this.status = AppointmentStatus.scheduled,
    this.notes,
    this.payment,
  });

  final String id;
  final String patientId;
  final String patientName;

  /// Backend fields `startTime` and `endTime`.
  final DateTime start;
  final DateTime end;
  final String? title;
  final String? location;
  final AppointmentStatus status;
  final String? notes;
  final Payment? payment;

  int get durationMinutes => end.difference(start).inMinutes;
  PaymentStatus get paymentStatus => payment?.status ?? PaymentStatus.unpaid;

  factory Appointment.fromJson(Map<String, dynamic> j) {
    // Therapist endpoints return patientId as {_id, name}; patient endpoints as a plain id.
    final p = j['patientId'];
    final pay = j['payment'];
    return Appointment(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      patientId: p is Map ? (p['_id'] ?? '').toString() : (p ?? '').toString(),
      patientName: p is Map ? (p['name'] ?? '').toString() : '',
      start: DateTime.parse(j['startTime'].toString()).toLocal(),
      end: DateTime.parse(j['endTime'].toString()).toLocal(),
      title: j['title'] as String?,
      location: j['location'] as String?,
      status: AppointmentStatus.parse(j['status'] as String?),
      notes: j['notes'] as String?,
      payment: pay is Map<String, dynamic> ? Payment.fromJson(pay) : null,
    );
  }

  /// Body for create and update. Empty strings clear optional fields on the server.
  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'startTime': start.toUtc().toIso8601String(),
        'endTime': end.toUtc().toIso8601String(),
        'title': title ?? '',
        'location': location ?? '',
        'notes': notes ?? '',
        'status': status.api,
        'payment': payment?.toJson(),
      };
}
