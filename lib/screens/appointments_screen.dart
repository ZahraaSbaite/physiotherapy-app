import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../utils/formatters.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() =>
      _AppointmentsScreenState();
}

class _AppointmentsScreenState
    extends ConsumerState<AppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  ({DateTime from, DateTime to}) _monthRange(DateTime focused) => (
    from: DateTime(focused.year, focused.month, 1),
    to: DateTime(focused.year, focused.month + 1, 0, 23, 59, 59),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final range = _monthRange(_focusedDay);

    final async = ref.watch(appointmentsInRangeProvider(range));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Month/Week view',
            icon: Icon(
              _format == CalendarFormat.month
                  ? Icons.view_week_outlined
                  : Icons.calendar_month,
            ),
            onPressed:
                () => setState(
                  () =>
                      _format =
                          _format == CalendarFormat.month
                              ? CalendarFormat.week
                              : CalendarFormat.month,
                ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            child: const Text('Today'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(
            '/admin/appointments/new?date=${isoDate(_selectedDay)}',
          );
          ref.invalidate(appointmentsInRangeProvider(range));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
      body: RefreshPage(
        onRefresh:
            () async => ref.refresh(
              appointmentsInRangeProvider(range).future,
            ),
        child: AsyncBody<List<Appointment>>(
          value: async,
          onRetry:
              () =>
                  ref.invalidate(appointmentsInRangeProvider(range)),
          builder: (all) {
            final dayItems =
                all
                    .where((a) => isSameDay(a.start, _selectedDay))
                    .toList()
                  ..sort((a, b) => a.start.compareTo(b.start));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:
                  MainAxisSize
                      .min, // 👈 FIX: Allow column to shrink-wrap its children
              children: [
                TableCalendar<Appointment>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _format,
                  selectedDayPredicate:
                      (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                  eventLoader:
                      (day) =>
                          all
                              .where((a) => isSameDay(a.start, day))
                              .toList(),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: colors.highlightSoft,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: colors.highlight,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: text.titleMedium!,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fmtDateLong(_selectedDay),
                        style: text.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${dayItems.length} appointment${dayItems.length == 1 ? '' : 's'}',
                        style: text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 👇 FIX: Use shrinkWrap instead of Expanded for scrollable parents
                if (dayItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Nothing scheduled',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap:
                        true, // 👈 FIX: Allows ListView to size to its children
                    physics:
                        const NeverScrollableScrollPhysics(), // 👈 FIX: Parent handles scrolling
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: dayItems.length,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: 10),
                    itemBuilder:
                        (_, i) => AppointmentTile(
                          appointment: dayItems[i],
                          onTap: () async {
                            await context.push(
                              '/admin/calendar/${dayItems[i].id}',
                            );
                            ref.invalidate(
                              appointmentsInRangeProvider(range),
                            );
                          },
                        ),
                  ),
                const SizedBox(
                  height: 16,
                ), // Bottom padding for scroll
              ],
            );
          },
        ),
      ),
    );
  }
}
