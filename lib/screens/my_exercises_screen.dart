import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/exercise.dart';
import '../services/exercise_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

String prescriptionText(ExerciseAssignment a) {
  final parts = <String>[];
  if (a.sets != null && a.reps != null) {
    parts.add('${a.sets} sets × ${a.reps} reps');
  } else if (a.reps != null) {
    parts.add('${a.reps} reps');
  }
  if (a.durationSeconds != null && a.durationSeconds! > 0) {
    parts.add('hold ${fmtSeconds(a.durationSeconds!)}');
  }
  return parts.isEmpty ? 'See instructions' : parts.join(' · ');
}

/// The "6/10" progress of an assignment.
String progressText(ExerciseAssignment a) =>
    '${a.doneCount}/${a.totalTimes} sessions done';

/// Patient: today's exercises.
class MyExercisesScreen extends ConsumerWidget {
  const MyExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final async = ref.watch(todayAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/patient/exercises/history'),
          ),
        ],
      ),
      body: RefreshPage(
        onRefresh: () async => ref.refresh(todayAssignmentsProvider.future),
        child: AsyncBody<List<ExerciseAssignment>>(
          value: async,
          onRetry: () => ref.invalidate(todayAssignmentsProvider),
          builder: (items) {
            final done = items.where((a) => a.completed).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: text.headlineSmall),
                Text(fmtDateLong(DateTime.now()),
                    style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.self_improvement_rounded,
                    title: 'Nothing scheduled today',
                    message: 'Your therapist hasn’t assigned exercises for today.',
                  )
                else ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$done of ${items.length} completed', style: text.titleMedium),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: done / items.length,
                            minHeight: 8,
                            backgroundColor: colors.secondary,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final a in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        onTap: () => context.push('/patient/exercises/${a.id}'),
                        child: Row(
                          children: [
                            Icon(
                              a.completed
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: a.completed ? colors.primary : colors.textSecondary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.exercise.title, style: text.titleSmall),
                                  const SizedBox(height: 2),
                                  Text(prescriptionText(a),
                                      style: text.bodySmall
                                          ?.copyWith(color: colors.textSecondary)),
                                  Text(progressText(a),
                                      style: text.bodySmall
                                          ?.copyWith(color: colors.textSecondary)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
