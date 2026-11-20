import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../utils/formatters.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Therapist: week calendar with the selected day's appointments.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _selected = dayOnly(DateTime.now());

  DateTime get _weekStart =>
      _selected.subtract(Duration(days: _selected.weekday - 1));

  DateTimeRange get _range =>
      DateTimeRange(start: _weekStart, end: _weekStart.add(const Duration(days: 7)));

  void _shiftWeek(int weeks) =>
      setState(() => _selected = _selected.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final async = ref.watch(appointmentsProvider(_range));
    final today = dayOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _selected = today),
            child: const Text('Today'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/appointments/new?date=${isoDate(_selected)}');
          ref.invalidate(appointmentsProvider(_range));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New appointment'),
      ),
      body: RefreshPage(
        onRefresh: () async => ref.refresh(appointmentsProvider(_range).future),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous week',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _shiftWeek(-1),
                ),
                Expanded(
                  child: Text(
                    fmtDateLong(_selected),
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Next week',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _shiftWeek(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AsyncBody<List<Appointment>>(
              value: async,
              onRetry: () => ref.invalidate(appointmentsProvider(_range)),
              builder: (all) {
                final daysWithItems = all.map((a) => dayOnly(a.start)).toSet();
                final dayItems = all
                    .where((a) => dayOnly(a.start) == _selected)
                    .toList()
                  ..sort((a, b) => a.start.compareTo(b.start));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: _DayCell(
                              day: _weekStart.add(Duration(days: i)),
                              selected: _weekStart.add(Duration(days: i)) == _selected,
                              isToday: _weekStart.add(Duration(days: i)) == today,
                              hasItems: daysWithItems
                                  .contains(_weekStart.add(Duration(days: i))),
                              onTap: () => setState(
                                  () => _selected = _weekStart.add(Duration(days: i))),
                            ),
                          ),
                      ],
                    ),
                    const SectionHeader('Appointments'),
                    if (dayItems.isEmpty)
                      const EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Nothing scheduled',
                        message: 'Add an appointment for this day.',
                      )
                    else
                      for (final a in dayItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppointmentTile(
                            appointment: a,
                            onTap: () async {
                              await context.push('/admin/appointments/${a.id}');
                              ref.invalidate(appointmentsProvider(_range));
                            },
                          ),
                        ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasItems,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool hasItems;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isToday ? colors.primary : colors.border),
        ),
        child: Column(
          children: [
            Text(weekdayShort(day.weekday),
                style: text.labelSmall?.copyWith(color: colors.textSecondary)),
            const SizedBox(height: 4),
            Text('${day.day}',
                style: text.titleSmall?.copyWith(
                    color: selected ? colors.primary : null)),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasItems ? colors.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
