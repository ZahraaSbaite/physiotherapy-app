import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/patient.dart';
import '../services/patient_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/page_body.dart';
import '../widgets/user_avatar.dart';
import 'patients_screen.dart' show StatusChip;
import '../widgets/page_helpers.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patientProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient'),
        actions: [
          IconButton(
            tooltip: 'Edit patient',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/admin/patients/$patientId/edit'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(patientProvider(patientId)),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () async => ref.refresh(patientProvider(patientId).future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageBody(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _Content(patient: p),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.patient});
  final Patient patient;

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _toast(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final next = !patient.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(next ? 'Activate account?' : 'Deactivate account?'),
        content: Text(next
            ? '${patient.name} will be able to sign in again.'
            : '${patient.name} will no longer be able to sign in. Their records are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(next ? 'Activate' : 'Deactivate')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(patientRepositoryProvider).setActive(patient.id, next);
      ref.invalidate(patientProvider(patient.id));
      ref.invalidate(patientsProvider);
      if (context.mounted) {
        _toast(context, next ? 'Account activated' : 'Account deactivated');
      }
    } catch (e) {
      if (context.mounted) {
        _toast(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New temporary password'),
            validator: (v) =>
                (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text);
              }
            },
            child: const Text('Reset password'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null) return;
    try {
      await ref
          .read(patientRepositoryProvider)
          .resetPassword(patient.id, password);
      if (context.mounted) _toast(context, 'Password reset');
    } catch (e) {
      if (context.mounted) {
        _toast(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;

    Widget row(String label, String? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label,
                    style: text.bodySmall?.copyWith(color: colors.textSecondary)),
              ),
              Expanded(
                child: Text(
                  (value == null || value.isEmpty) ? '—' : value,
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            UserAvatar(name: patient.name),
            const SizedBox(height: 12),
            Text(patient.name, style: text.titleLarge),
            const SizedBox(height: 8),
            StatusChip(active: patient.isActive),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            children: [
              row('Email', patient.email),
              row('Phone', patient.phone),
              row('Date of birth',
                  patient.dateOfBirth == null ? null : _date(patient.dateOfBirth!)),
              row('Medical notes', patient.medicalNotes),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push('/admin/patients/${patient.id}/progress'),
          icon: const Icon(Icons.insights_rounded),
          label: const Text('Exercises and progress'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.push('/admin/patients/${patient.id}/assign'),
          icon: const Icon(Icons.fitness_center_rounded),
          label: const Text('Assign exercise'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.push('/admin/appointments/new'),
          icon: const Icon(Icons.event_rounded),
          label: const Text('Schedule appointment'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _resetPassword(context, ref),
          icon: const Icon(Icons.lock_reset_rounded),
          label: const Text('Reset password'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _toggleActive(context, ref),
          icon: Icon(patient.isActive
              ? Icons.person_off_outlined
              : Icons.person_outline_rounded),
          label: Text(patient.isActive ? 'Deactivate account' : 'Activate account'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
