import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'accent_badge.dart';

class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip({super.key, required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Color bg, fg, border;
    switch (status) {
      case AppointmentStatus.scheduled:
        bg = colors.highlightSoft;
        fg = colors.highlight;
        border = colors.highlight.withValues(alpha: 0.3);
        break;
      case AppointmentStatus.completed:
        bg = colors.successSoft;
        fg = colors.success;
        border = colors.success.withValues(alpha: 0.3);
        break;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.noShow:
        bg = colors.errorSoft;
        fg = colors.error;
        border = colors.error.withValues(alpha: 0.3);
        break;
      default:
        bg = colors.secondary;
        fg = colors.primary;
        border = colors.border;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
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

  bool get _isToday {
    final n = DateTime.now();
    final a = appointment.start;
    return a.year == n.year && a.month == n.month && a.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final a = appointment;
    return AppCard(
      onTap: onTap,
      isHighlighted:
          _isToday, // 👈 today's card pops with a terracotta ring
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fmtTime(a.start), style: text.titleMedium),
              Text(
                '${a.durationMinutes} min',
                style: text.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showPatient
                      ? a.patientName
                      : 'Physiotherapy session',
                  style: text.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showDate)
                  Text(
                    fmtDateLong(a.start),
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                if (_isToday) const SizedBox(height: 6),
                if (_isToday)
                  const AccentBadge(label: 'Today', icon: Icons.bolt),
              ],
            ),
          ),
          AppointmentStatusChip(status: a.status),
        ],
      ),
    );
  }
}
