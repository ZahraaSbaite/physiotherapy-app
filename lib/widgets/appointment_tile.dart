import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip({super.key, required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filled = status == AppointmentStatus.scheduled ||
        status == AppointmentStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? colors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: filled ? colors.primary : colors.textSecondary),
      ),
    );
  }
}

class AppointmentTile extends StatelessWidget {
  const AppointmentTile({
    super.key,
    required this.appointment,
    required this.onTap,
    this.showPatient = true,
    this.showDate = false,
  });

  final Appointment appointment;
  final VoidCallback onTap;
  final bool showPatient;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final a = appointment;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fmtTime(a.start), style: text.titleMedium),
              Text('${a.durationMinutes} min',
                  style: text.bodySmall?.copyWith(color: colors.textSecondary)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showPatient ? a.patientName : 'Physiotherapy session',
                  style: text.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showDate)
                  Text(fmtDateLong(a.start),
                      style: text.bodySmall
                          ?.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          AppointmentStatusChip(status: a.status),
        ],
      ),
    );
  }
}
