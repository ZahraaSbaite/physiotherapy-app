import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../services/appointment_repository.dart';
import '../services/exercise_repository.dart';
import '../services/patient_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';
import '../widgets/user_avatar.dart';
import 'patients_screen.dart' show StatusChip;

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Patient?'),
            content: const Text(
              'This will permanently delete this patient and all their associated data. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _performDelete(context, ref);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _performDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(patientRepositoryProvider).delete(patientId);
      ref.invalidate(patientsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient deleted successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patientProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient'),
        actions: [
          IconButton(
            tooltip: 'Delete patient',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref),
          ),
          IconButton(
            tooltip: 'Edit patient',
            icon: const Icon(Icons.edit_outlined),
            onPressed:
                () => context.push('/admin/patients/$patientId/edit'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error:
            (e, _) => ErrorView(
              message: e.toString().replaceFirst('Exception: ', ''),
              onRetry:
                  () => ref.invalidate(patientProvider(patientId)),
            ),
        data:
            (p) => RefreshIndicator(
              onRefresh:
                  () async =>
                      ref.refresh(patientProvider(patientId).future),
              child: _Content(patient: p),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final next = !patient.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              next ? 'Activate account?' : 'Deactivate account?',
            ),
            content: Text(
              next
                  ? '${patient.name} will be able to sign in again.'
                  : '${patient.name} will no longer be able to sign in. Their records are kept.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(next ? 'Activate' : 'Deactivate'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(patientRepositoryProvider)
          .setActive(patient.id, next);
      ref.invalidate(patientProvider(patient.id));
      ref.invalidate(patientsProvider);
      if (context.mounted)
        _toast(
          context,
          next ? 'Account activated' : 'Account deactivated',
        );
    } catch (e) {
      if (context.mounted)
        _toast(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _resetPassword(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final password = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset password'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New temporary password',
                ),
                validator:
                    (v) =>
                        (v == null || v.length < 8)
                            ? 'Use at least 8 characters'
                            : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(ctx, controller.text);
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
      if (context.mounted)
        _toast(context, e.toString().replaceFirst('Exception: ', ''));
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
            child: Text(
              label,
              style: text.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              UserAvatar(name: patient.name),
              const SizedBox(height: 12),
              Text(patient.name, style: text.titleLarge),
              const SizedBox(height: 8),
              StatusChip(active: patient.isActive),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    row('Email', patient.email),
                    row('Phone', patient.phone),
                    row(
                      'Date of birth',
                      patient.dateOfBirth == null
                          ? null
                          : _date(patient.dateOfBirth!),
                    ),
                    row('Medical notes', patient.medicalNotes),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed:
                        () => context.push(
                          '/admin/patients/${patient.id}/progress',
                        ),
                    icon: const Icon(Icons.insights_rounded),
                    label: const Text('Full History'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        () => context.push(
                          '/admin/patients/${patient.id}/assign',
                        ),
                    icon: const Icon(Icons.fitness_center_rounded),
                    label: const Text('Assign Exercise'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        () => context.push(
                          '/admin/appointments/new?patientId=${patient.id}',
                        ),
                    icon: const Icon(Icons.event_rounded),
                    label: const Text('Schedule'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _resetPassword(context, ref),
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Reset Password'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _toggleActive(context, ref),
                    icon: Icon(
                      patient.isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outline_rounded,
                    ),
                    label: Text(
                      patient.isActive ? 'Deactivate' : 'Activate',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.textSecondary,
                  indicatorColor: colors.primary,
                  tabs: const [
                    Tab(text: 'Appointments'),
                    Tab(text: 'Exercises'),
                    Tab(text: 'Payments'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AppointmentsTab(patientId: patient.id),
                      _ExercisesTab(patientId: patient.id),
                      _PaymentsTab(patientId: patient.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 👇 TAB 1: APPOINTMENTS
class _AppointmentsTab extends ConsumerWidget {
  const _AppointmentsTab({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patientAppointmentsProvider(patientId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (appointments) {
        if (appointments.isEmpty)
          return const Center(child: Text('No appointments found.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final a = appointments[i];
            return AppointmentTile(
              appointment: a,
              showPatient: false,
              showDate: true,
              onTap: () => context.push('/admin/calendar/${a.id}'),
            );
          },
        );
      },
    );
  }
}

// 👇 TAB 2: EXERCISES
class _ExercisesTab extends ConsumerWidget {
  const _ExercisesTab({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patientAssignmentsProvider(patientId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty)
          return const Center(child: Text('No exercises assigned.'));
        final colors = context.appColors;
        final text = Theme.of(context).textTheme;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final a = items[i];
            return AppCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.exercise.title,
                            style: text.titleSmall,
                          ),
                        ),
                        if (!a.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.errorSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Stopped',
                              style: text.labelSmall?.copyWith(
                                color: colors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${a.doneCount}/${a.totalTimes} sessions done',
                      style: text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: a.progress,
                        minHeight: 6,
                        backgroundColor: colors.secondary,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 👇 TAB 3: PAYMENTS & BALANCE
class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patientAppointmentsProvider(patientId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (appointments) {
        double totalBilled = 0;
        double totalPaid = 0;

        for (final a in appointments) {
          if (a.payment != null && a.payment!.amount != null) {
            totalBilled += a.payment!.amount!;
            if (a.payment!.status == PaymentStatus.paid) {
              totalPaid += a.payment!.amount!;
            } else if (a.payment!.status == PaymentStatus.partial) {
              totalPaid += a.payment!.paidAmount;
            }
          }
        }

        final balanceOwed = totalBilled - totalPaid;
        final colors = context.appColors;
        final text = Theme.of(context).textTheme;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Billed', style: text.bodyMedium),
                        Text(
                          '\$${totalBilled.toStringAsFixed(2)}',
                          style: text.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Paid', style: text.bodyMedium),
                        Text(
                          '\$${totalPaid.toStringAsFixed(2)}',
                          style: text.titleMedium?.copyWith(
                            color: colors.success,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Balance Owed',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${balanceOwed.toStringAsFixed(2)}',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                balanceOwed > 0
                                    ? colors.error
                                    : colors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Payment History', style: text.titleMedium),
            const SizedBox(height: 12),
            if (appointments
                .where(
                  (a) =>
                      a.payment != null && a.payment!.amount != null,
                )
                .isEmpty)
              const Center(child: Text('No payment records found.'))
            else
              ...appointments
                  .where(
                    (a) =>
                        a.payment != null &&
                        a.payment!.amount != null,
                  )
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fmtDateLong(a.start),
                                      style: text.bodyMedium,
                                    ),
                                    Text(
                                      a.payment!.summary,
                                      style: text.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppointmentStatusChip(status: a.status),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
          ],
        );
      },
    );
  }
}
