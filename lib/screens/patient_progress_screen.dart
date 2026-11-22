import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/exercise.dart';
import '../services/exercise_repository.dart';
import '../services/patient_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Therapist: a patient's assigned exercises and completion history.
class PatientProgressScreen extends ConsumerWidget {
  const PatientProgressScreen({super.key, required this.patientId});
  final String patientId;

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    ExerciseAssignment a,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove exercise?'),
            content: Text(
              '${a.exercise.title} will no longer appear in this patient’s program.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(exerciseRepositoryProvider)
          .removeAssignment(a.id);
      ref.invalidate(patientAssignmentsProvider(patientId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }

  String _prescription(ExerciseAssignment a) {
    final parts = <String>[];
    if (a.sets != null && a.reps != null) {
      parts.add('${a.sets} × ${a.reps}');
    } else if (a.reps != null) {
      parts.add('${a.reps} reps');
    }
    if (a.durationSeconds != null) {
      parts.add('hold ${fmtSeconds(a.durationSeconds!)}');
    }
    if (a.restSeconds != null) {
      parts.add('rest ${fmtSeconds(a.restSeconds!)}');
    }
    return parts.isEmpty ? 'No sets or reps set' : parts.join(', ');
  }

  String _schedule(ExerciseAssignment a) {
    final range = (a.startDate != null && a.endDate != null)
        ? ' · ${fmtDate(a.startDate!)} to ${fmtDate(a.endDate!)}'
        : '';
    switch (a.repeatType) {
      case RepeatType.daily:
        return 'Every day$range';
      case RepeatType.weekly:
        final sorted = [...a.daysOfWeek]..sort();
        return '${sorted.map(weekdayShort).join(', ')}$range';
      case RepeatType.auto:
        return 'Spread evenly$range';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final patient = ref.watch(patientProvider(patientId));
    final assignments = ref.watch(
      patientAssignmentsProvider(patientId),
    );
    final completions = ref.watch(
      patientCompletionsProvider(patientId),
    );

    Future<void> refresh() async {
      ref.invalidate(patientAssignmentsProvider(patientId));
      ref.invalidate(patientCompletionsProvider(patientId));
      await ref.read(patientCompletionsProvider(patientId).future);
    }

    return Scaffold(
      appBar: AppBar(title: Text(patient.value?.name ?? 'Progress')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => context.push('/admin/patients/$patientId/assign'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Assign exercise'),
      ),
      body: RefreshPage(
        onRefresh: refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AsyncBody<List<Completion>>(
              value: completions,
              onRetry:
                  () => ref.invalidate(
                    patientCompletionsProvider(patientId),
                  ),
              builder: (all) {
                final weekAgo = DateTime.now().subtract(
                  const Duration(days: 7),
                );
                final week =
                    all
                        .where((c) => c.completedAt.isAfter(weekAgo))
                        .toList();
                final pains =
                    week
                        .map((c) => c.painLevel)
                        .whereType<int>()
                        .toList();
                final avg =
                    pains.isEmpty
                        ? '—'
                        : (pains.reduce((a, b) => a + b) /
                                pains.length)
                            .toStringAsFixed(1);
                Widget stat(String value, String label) => Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value, style: text.headlineSmall),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: text.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        stat('${week.length}', 'Completed in 7 days'),
                        const SizedBox(width: 12),
                        stat(avg, 'Average pain (0–10)'),
                      ],
                    ),
                    const SectionHeader('Recent activity'),
                    if (all.isEmpty)
                      const EmptyState(
                        icon: Icons.insights_rounded,
                        title: 'No activity yet',
                        message:
                            'Completed exercises will appear here.',
                      )
                    else
                      for (final c in all)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.exerciseTitle,
                                        style: text.titleSmall,
                                      ),
                                    ),
                                    if (c.painLevel != null)
                                      Text(
                                        'Pain ${c.painLevel}/10',
                                        style: text.labelMedium
                                            ?.copyWith(
                                              color:
                                                  colors
                                                      .textSecondary,
                                            ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${fmtDateLong(c.completedAt)} · ${fmtTime(c.completedAt)}',
                                  style: text.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                if ((c.patientNote ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    c.patientNote!,
                                    style: text.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
            const SectionHeader('Assigned exercises'),
            AsyncBody<List<ExerciseAssignment>>(
              value: assignments,
              onRetry:
                  () => ref.invalidate(
                    patientAssignmentsProvider(patientId),
                  ),
              builder: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'No exercises assigned',
                    message:
                        'Assign an exercise to start this patient’s program.',
                  );
                }
                return Column(
                  children: [
                    for (final a in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.exercise.title,
                                      style: text.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _prescription(a),
                                      style: text.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _schedule(a),
                                      style: text.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${a.doneCount}/${a.totalTimes} sessions done',
                                      style: text.labelMedium?.copyWith(
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
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
                              IconButton(
                                tooltip: 'Remove exercise',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                ),
                                onPressed:
                                    () => _remove(context, ref, a),
                              ),
                            ],
                          ),
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
