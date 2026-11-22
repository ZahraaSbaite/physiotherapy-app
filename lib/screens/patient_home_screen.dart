import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/appointment.dart';
import '../services/appointment_repository.dart';
import '../services/auth_controller.dart';
import '../utils/formatters.dart';
import '../widgets/announcements_preview.dart';
import '../widgets/appear_animation.dart';
import '../widgets/home_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/app_card.dart';
import '../widgets/today_hero_card.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

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
              const AppearAnimation(index: 1, child: TodayHeroCard()),
              const SizedBox(height: AppSpacing.xl),
              const AppearAnimation(
                index: 2,
                child: SectionTitle('Coming up'),
              ),
              // 👇 REAL NEXT APPOINTMENT CARD 👇
              const AppearAnimation(
                index: 3,
                child: _NextAppointmentCard(),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AppearAnimation(
                index: 4,
                child: SectionTitle('From your therapist'),
              ),
              const AppearAnimation(
                index: 5,
                child: AnnouncementsPreview(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 👇 NEW: Real Next Appointment Card
class _NextAppointmentCard extends ConsumerWidget {
  const _NextAppointmentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfNext30Days = startOfDay.add(const Duration(days: 30));

    final async = ref.watch(
      myAppointmentsInRangeProvider((
        from: startOfDay,
        to: endOfNext30Days,
      )),
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
                'Could not load your appointments',
                style: text.bodyMedium?.copyWith(color: colors.error),
              ),
            ),
          ),
      data: (appointments) {
        final upcoming =
            appointments
                .where(
                  (a) =>
                      a.status == AppointmentStatus.scheduled &&
                      a.start.isAfter(now),
                )
                .toList();

        if (upcoming.isEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next appointment',
                          style: text.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No upcoming appointments. Your therapist will schedule one soon.',
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

        final next = upcoming.first;
        final daysUntil = next.start.difference(now).inDays;
        String whenLabel;
        if (daysUntil == 0) {
          whenLabel = 'Today at ${fmtTime(next.start)}';
        } else if (daysUntil == 1) {
          whenLabel = 'Tomorrow at ${fmtTime(next.start)}';
        } else if (daysUntil < 7) {
          whenLabel =
              'In $daysUntil days · ${fmtDateLong(next.start)}';
        } else {
          whenLabel = fmtDateLong(next.start);
        }

        return AppCard(
          onTap:
              () => context.push('/patient/appointments/${next.id}'),
          isHighlighted:
              daysUntil <=
              1, // Pops with terracotta if today/tomorrow
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.highlightSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: colors.highlight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next appointment',
                      style: text.titleSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(whenLabel, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${next.durationMinutes} min${(next.location ?? '').isNotEmpty ? ' · ${next.location}' : ''}',
                      style: text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }
}
