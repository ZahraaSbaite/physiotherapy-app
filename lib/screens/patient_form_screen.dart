import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/patient.dart';
import '../services/patient_repository.dart';
import '../widgets/page_body.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Create (patientId == null) or edit an existing patient.
class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key, this.patientId});
  final String? patientId;

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _condition = TextEditingController();
  final _notes = TextEditingController();
  final _password = TextEditingController();
  DateTime? _dob;
  bool _saving = false;
  bool _hidePassword = true;
  bool _prefilled = false;

  bool get _isEdit => widget.patientId != null;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _condition, _notes, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(Patient p) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = p.name;
    _email.text = p.email;
    _phone.text = p.phone ?? '';
    _condition.text = p.condition ?? '';
    _notes.text = p.notes ?? '';
    _dob = p.dateOfBirth;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(patientRepositoryProvider);
    final patient = Patient(
      id: widget.patientId ?? '',
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      dateOfBirth: _dob,
      condition: _condition.text.trim(),
      notes: _notes.text.trim(),
    );
    try {
      if (_isEdit) {
        await repo.update(widget.patientId!, patient);
        ref.invalidate(patientProvider(widget.patientId!));
      } else {
        await repo.create(patient, password: _password.text);
      }
      ref.invalidate(patientsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Patient updated' : 'Patient created')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final async = ref.watch(patientProvider(widget.patientId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Edit patient')),
        body: async.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(patientProvider(widget.patientId!)),
          ),
          data: (p) {
            _prefill(p);
            return _buildForm(context);
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('New patient')),
      body: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final dobText = _dob == null
        ? 'Date of birth (optional)'
        : '${_dob!.day.toString().padLeft(2, '0')}/'
            '${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';

    return SingleChildScrollView(
      child: PageBody(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Enter the patient’s name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                    return ok ? null : 'Enter a valid email address';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    child: Text(dobText),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _condition,
                  decoration: const InputDecoration(
                      labelText: 'Condition / diagnosis (optional)'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                      labelText: 'Notes (optional)', alignLabelWithHint: true),
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Temporary password',
                      suffixIcon: IconButton(
                        icon: Icon(_hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Use at least 8 characters'
                        : null,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const ButtonSpinner()
                      : Text(_isEdit ? 'Save changes' : 'Create patient'),
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
