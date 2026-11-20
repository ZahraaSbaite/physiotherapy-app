import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Patient: upcoming and previous appointments.
class MyAppointmentsScreen extends ConsumerWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAppointmentsProvider);

    Widget list(List<Appointment> items, String emptyTitle, String emptyMessage) {
      return RefreshPage(
        onRefresh: () async => ref.refresh(myAppointmentsProvider.future),
        child: items.isEmpty
            ? EmptyState(
                icon: Icons.event_available_rounded, title: emptyTitle, message: emptyMessage)
            : Column(
                children: [
                  for (final a in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppointmentTile(
                        appointment: a,
                        showPatient: false,
                        showDate: true,
                        onTap: () => context.push('/patient/appointments/${a.id}'),
                      ),
                    ),
                ],
              ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
          bottom: const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'Previous')]),
        ),
        body: AsyncBody<List<Appointment>>(
          value: async,
          onRetry: () => ref.invalidate(myAppointmentsProvider),
          builder: (all) {
            final now = DateTime.now();
            final upcoming = all
                .where((a) =>
                    a.end.isAfter(now) && a.status == AppointmentStatus.scheduled)
                .toList()
              ..sort((a, b) => a.start.compareTo(b.start));
            final previous = all.where((a) => !upcoming.contains(a)).toList()
              ..sort((a, b) => b.start.compareTo(a.start));
            return TabBarView(children: [
              list(upcoming, 'No upcoming appointments',
                  'Your next appointment will appear here once it is scheduled.'),
              list(previous, 'No previous appointments',
                  'Past appointments will be listed here.'),
            ]);
          },
        ),
      ),
    );
  }
}
