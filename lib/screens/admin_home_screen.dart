import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/widgets/placeholders.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/appointment.dart';
import '../models/exercise.dart';
import '../services/appointment_repository.dart';
import '../services/auth_controller.dart';
import '../services/exercise_repository.dart';
import '../utils/formatters.dart';
import '../widgets/announcements_preview.dart';
import '../widgets/appear_animation.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/home_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/app_card.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final notesAsync = ref.watch(unreadNotesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              AppearAnimation(
                child: HomeHeader(name: user?.name ?? ''),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const AppearAnimation(
                index: 1,
                child: SectionTitle('Today'),
              ),
              // 👇 REAL TODAY'S SCHEDULE 👇
              const AppearAnimation(
                index: 2,
                child: _TodayScheduleCard(),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AppearAnimation(
                index: 3,
                child: SectionTitle('Your patients'),
              ),
              const AppearAnimation(
                index: 3,
                child: AdminAnnouncementsCard(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppearAnimation(
                index: 4,
                child: notesAsync.when(
                  loading:
                      () => const AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  error:
                      (e, _) => AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Error loading notes'),
                        ),
                      ),
                  data:
                      (notesData) => _PatientNotesCard(
                        count: notesData.count,
                        notes: notesData.notes,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 👇 NEW: Real Today's Schedule Card
class _TodayScheduleCard extends ConsumerWidget {
  const _TodayScheduleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final async = ref.watch(
      appointmentsInRangeProvider((from: startOfDay, to: endOfDay)),
    );

    return async.when(
      loading:
          () => const AppCard(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error:
          (e, _) => AppCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Could not load today\'s schedule',
                style: text.bodyMedium?.copyWith(color: colors.error),
              ),
            ),
          ),
      data: (appointments) {
        final todayAppointments =
            appointments
                .where((a) => a.status == AppointmentStatus.scheduled)
                .toList();

        if (todayAppointments.isEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.today_outlined,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's schedule",
                          style: text.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No appointments scheduled for today.',
                          style: text.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.today_outlined,
                    color: colors.highlight,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Today's schedule · ${todayAppointments.length} appointment${todayAppointments.length == 1 ? '' : 's'}",
                      style: text.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/admin/calendar'),
                    child: const Text('View calendar'),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...todayAppointments
                  .take(3)
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppointmentTile(
                        appointment: a,
                        showPatient: true,
                        showDate: false,
                        onTap:
                            () => context.push(
                              '/admin/calendar/${a.id}',
                            ),
                      ),
                    ),
                  ),
              if (todayAppointments.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/admin/calendar'),
                    child: Text(
                      'View all ${todayAppointments.length} appointments',
                      style: text.labelMedium?.copyWith(
                        color: colors.highlight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PatientNotesCard extends ConsumerWidget {
  const _PatientNotesCard({required this.count, required this.notes});
  final int count;
  final List<UnreadNote> notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_alt_outlined,
                color: colors.highlight,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Notes', style: text.titleMedium),
                    Text(
                      count > 0
                          ? '$count new note${count == 1 ? '' : 's'} from completed exercises'
                          : 'No new notes',
                      style: text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(exerciseRepositoryProvider)
                        .markNotesRead();
                    ref.invalidate(unreadNotesProvider);
                  },
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          if (count > 0) ...[
            const Divider(height: 24),
            ...notes
                .take(3)
                .map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.patientName,
                                style: text.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                note.exerciseTitle,
                                style: text.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                note.patientNote,
                                style: text.bodyMedium,
                              ),
                              if (note.painLevel != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                  ),
                                  child: Text(
                                    'Pain: ${note.painLevel}/10',
                                    style: text.labelSmall?.copyWith(
                                      color: colors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (count > 3)
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'View all $count notes',
                    style: text.labelMedium?.copyWith(
                      color: colors.highlight,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
