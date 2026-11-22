import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/appointment.dart';
import '../models/patient.dart';
import '../services/appointment_repository.dart';
import '../services/auth_controller.dart';
import '../services/patient_repository.dart';
import '../utils/formatters.dart';
import '../widgets/page_body.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({
    super.key,
    this.appointmentId,
    this.initialDate,
    this.patientId,
  });
  final String? appointmentId;
  final DateTime? initialDate;
  final String? patientId;

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState
    extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  final _amount = TextEditingController();
  final _paidAmount = TextEditingController();
  final _currency = TextEditingController();
  String? _patientId;
  late DateTime _date = dayOnly(widget.initialDate ?? DateTime.now());
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _duration = 60;
  AppointmentStatus _status = AppointmentStatus.scheduled;
  PaymentStatus _payment = PaymentStatus.unpaid;
  PaymentMethod? _method;
  bool _saving = false;
  bool _prefilled = false;
  bool _sendReminder = false;

  // 👇 Recurrence
  String _recurrenceType = 'none';
  int _recurrenceCount = 4;

  bool get _isEdit => widget.appointmentId != null;

  @override
  void initState() {
    super.initState();
    _currency.text =
        ref.read(authControllerProvider).user?.defaultCurrency ??
        'USD';
    _patientId = widget.patientId;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _location,
      _notes,
      _amount,
      _paidAmount,
      _currency,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(Appointment a) {
    if (_prefilled) return;
    _prefilled = true;
    _patientId = a.patientId;
    _date = dayOnly(a.start);
    _time = TimeOfDay(hour: a.start.hour, minute: a.start.minute);
    _duration = a.durationMinutes;
    _status = a.status;
    _title.text = a.title ?? '';
    _location.text = a.location ?? '';
    _notes.text = a.notes ?? '';
    _sendReminder = a.sendReminder;
    final pay = a.payment;
    if (pay != null) {
      _payment = pay.status;
      _method = pay.method;
      _currency.text = pay.currency;
      _amount.text = pay.amount?.toString() ?? '';
      _paidAmount.text =
          pay.status == PaymentStatus.partial
              ? pay.paidAmount.toString()
              : '';
    }
  }

  Payment? _buildPayment() {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null &&
        _payment == PaymentStatus.unpaid &&
        _method == null) {
      return null;
    }
    return Payment(
      status: _payment,
      amount: amount,
      currency:
          _currency.text.trim().isEmpty
              ? 'USD'
              : _currency.text.trim().toUpperCase(),
      method: _method,
      paidAmount: double.tryParse(_paidAmount.text.trim()) ?? 0,
    );
  }

  String? _money(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim());
    return (n == null || n < 0) ? 'Enter a valid amount' : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a patient')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(appointmentRepositoryProvider);
    final startTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final appointment = Appointment(
      id: widget.appointmentId ?? '',
      patientId: _patientId!,
      patientName: '',
      start: startTime,
      end: startTime.add(Duration(minutes: _duration)),
      title: _title.text.trim(),
      location: _location.text.trim(),
      status: _status,
      notes: _notes.text.trim(),
      payment: _buildPayment(),
      sendReminder: _sendReminder,
    );

    try {
      if (_isEdit) {
        await repo.update(widget.appointmentId!, appointment);
        ref.invalidate(
          appointmentProvider((
            id: widget.appointmentId!,
            mine: false,
          )),
        );
      } else {
        // 👇 Build payload with recurrence
        final payload = appointment.toJson();
        if (_recurrenceType == 'weekly' && _recurrenceCount > 1) {
          payload['recurrence'] = {
            'type': 'weekly',
            'count': _recurrenceCount,
          };
        }
        await repo.createWithRecurrence(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Appointment updated'
                : 'Appointment${_recurrenceType == 'weekly' && _recurrenceCount > 1 ? 's' : ''} scheduled',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final key = (id: widget.appointmentId!, mine: false);
      return Scaffold(
        appBar: AppBar(title: const Text('Edit appointment')),
        body: AsyncBody<Appointment>(
          value: ref.watch(appointmentProvider(key)),
          onRetry: () => ref.invalidate(appointmentProvider(key)),
          builder: (a) {
            _prefill(a);
            return _form();
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('New appointment')),
      body: _form(),
    );
  }

  Widget _form() {
    final patients = ref.watch(patientsProvider);
    return SingleChildScrollView(
      child: PageBody(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                patients.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(errorText(e)),
                  data: (List<Patient> all) {
                    final options =
                        all
                            .where(
                              (p) => p.isActive || p.id == _patientId,
                            )
                            .toList();
                    return DropdownButtonFormField<String>(
                      initialValue: _patientId,
                      decoration: const InputDecoration(
                        labelText: 'Patient',
                      ),
                      items: [
                        for (final p in options)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                      ],
                      onChanged:
                          (v) => setState(() => _patientId = v),
                      validator:
                          (v) =>
                              v == null ? 'Choose a patient' : null,
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                          ),
                          child: Text(fmtDate(_date)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                          ),
                          child: Text(
                            '${two(_time.hour)}:${two(_time.minute)}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _duration,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                  ),
                  items: [
                    for (final m
                        in {30, 45, 60, 90, _duration}.toList()
                          ..sort())
                      DropdownMenuItem(
                        value: m,
                        child: Text('$m minutes'),
                      ),
                  ],
                  onChanged:
                      (v) => setState(() => _duration = v ?? 60),
                ),

                // 👇 RECURRENCE SECTION
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _recurrenceType,
                  decoration: const InputDecoration(
                    labelText: 'Repeat',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'none',
                      child: Text('Does not repeat'),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('Weekly'),
                    ),
                  ],
                  onChanged:
                      (v) => setState(
                        () => _recurrenceType = v ?? 'none',
                      ),
                ),
                if (_recurrenceType == 'weekly') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: '$_recurrenceCount',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'For how many weeks?',
                      helperText: 'e.g., 4 weeks (max 52)',
                    ),
                    onChanged: (v) {
                      final count = int.tryParse(v);
                      if (count != null && count > 0 && count <= 52) {
                        setState(() => _recurrenceCount = count);
                      }
                    },
                  ),
                ],

                const SizedBox(height: 14),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: const Text('Send appointment reminder'),
                  subtitle: const Text(
                    'Notify the patient before the session',
                  ),
                  value: _sendReminder,
                  onChanged: (v) => setState(() => _sendReminder = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_isEdit) ...[
                  const SectionHeader('Status'),
                  DropdownButtonFormField<AppointmentStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    items: [
                      for (final s in AppointmentStatus.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ),
                    ],
                    onChanged:
                        (v) => setState(() => _status = v ?? _status),
                  ),
                ],
                const SectionHeader('Payment'),
                DropdownButtonFormField<PaymentStatus>(
                  initialValue: _payment,
                  decoration: const InputDecoration(
                    labelText: 'Payment status',
                  ),
                  items: [
                    for (final s in PaymentStatus.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ),
                  ],
                  onChanged:
                      (v) => setState(() => _payment = v ?? _payment),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amount,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                        ),
                        validator: _money,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _currency,
                        textCapitalization:
                            TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_payment == PaymentStatus.partial) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _paidAmount,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                    decoration: const InputDecoration(
                      labelText: 'Amount paid so far',
                    ),
                    validator: (v) {
                      final err = _money(v);
                      if (err != null) return err;
                      final paid = double.tryParse((v ?? '').trim());
                      final total = double.tryParse(
                        _amount.text.trim(),
                      );
                      if (paid == null ||
                          paid <= 0 ||
                          total == null ||
                          paid >= total) {
                        return 'Enter an amount above 0 and below the total';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<PaymentMethod?>(
                  initialValue: _method,
                  decoration: const InputDecoration(
                    labelText: 'Payment method (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<PaymentMethod?>(
                      value: null,
                      child: Text('Not set'),
                    ),
                    for (final m in PaymentMethod.values)
                      DropdownMenuItem<PaymentMethod?>(
                        value: m,
                        child: Text(m.label),
                      ),
                  ],
                  onChanged: (v) => setState(() => _method = v),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child:
                      _saving
                          ? const ButtonSpinner()
                          : Text(
                            _isEdit
                                ? 'Save changes'
                                : 'Schedule appointment',
                          ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
