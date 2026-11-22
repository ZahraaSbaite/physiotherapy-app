import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/page_helpers.dart';

/// Appointment details. Therapists (readOnly: false) can change status,
/// payment, edit or delete. Patients (readOnly: true) only view.
class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.readOnly = false,
  });

  final String appointmentId;
  final bool readOnly;

  AppointmentKey get _key => (id: appointmentId, mine: readOnly);

  Future<void> _patch(BuildContext context, WidgetRef ref, Map<String, dynamic> fields,
      String message) async {
    try {
      await ref.read(appointmentRepositoryProvider).patch(appointmentId, fields);
      ref.invalidate(appointmentProvider(_key));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete appointment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(appointmentRepositoryProvider).delete(appointmentId);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final async = ref.watch(appointmentProvider(_key));

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(label,
                    style: text.bodySmall?.copyWith(color: colors.textSecondary)),
              ),
              Expanded(child: Text(value.isEmpty ? '—' : value, style: text.bodyMedium)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment'),
        actions: [
          if (!readOnly)
            IconButton(
              tooltip: 'Edit appointment',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push('/admin/appointments/$appointmentId/edit');
                ref.invalidate(appointmentProvider(_key));
              },
            ),
        ],
      ),
      body: RefreshPage(
        onRefresh: () async => ref.refresh(appointmentProvider(_key).future),
        child: AsyncBody<Appointment>(
          value: async,
          onRetry: () => ref.invalidate(appointmentProvider(_key)),
          builder: (a) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(readOnly ? 'Physiotherapy session' : a.patientName,
                        style: text.titleLarge),
                  ),
                  AppointmentStatusChip(status: a.status),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    row('Date', fmtDateLong(a.start)),
                    row('Time', '${fmtTime(a.start)} – ${fmtTime(a.end)}'),
                    row('Duration', '${a.durationMinutes} minutes'),
                    if ((a.title ?? '').isNotEmpty) row('Title', a.title!),
                    if ((a.location ?? '').isNotEmpty) row('Location', a.location!),
                    row('Notes', a.notes ?? ''),
                    if (!readOnly || a.payment != null)
                      row('Payment', a.payment?.summary ?? PaymentStatus.unpaid.label),
                    if (a.payment?.method != null) row('Method', a.payment!.method!.label),
                  ],
                ),
              ),
              if (!readOnly) ...[
                const SectionHeader('Actions'),
                if (a.status == AppointmentStatus.scheduled) ...[
                  FilledButton(
                    onPressed: () => _patch(context, ref,
                        {'status': AppointmentStatus.completed.api}, 'Marked as completed'),
                    child: const Text('Mark as completed'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _patch(context, ref,
                        {'status': AppointmentStatus.noShow.api}, 'Marked as no show'),
                    child: const Text('Mark as no show'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _patch(context, ref,
                        {'status': AppointmentStatus.cancelled.api}, 'Appointment cancelled'),
                    child: const Text('Cancel appointment'),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton(
                  onPressed: () {
                    final paid = a.paymentStatus == PaymentStatus.paid;
                    _patch(
                      context,
                      ref,
                      {
                        'payment': {
                          'status': (paid ? PaymentStatus.unpaid : PaymentStatus.paid).api,
                        },
                      },
                      paid ? 'Marked as unpaid' : 'Marked as paid',
                    );
                  },
                  child: Text(a.paymentStatus == PaymentStatus.paid
                      ? 'Mark as unpaid'
                      : 'Mark as paid'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _delete(context, ref),
                  child: const Text('Delete appointment'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
