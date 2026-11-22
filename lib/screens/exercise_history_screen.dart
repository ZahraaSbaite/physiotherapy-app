import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/exercise.dart';
import '../services/exercise_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Patient: completion history grouped by day.
class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final async = ref.watch(myCompletionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: RefreshPage(
        onRefresh: () async => ref.refresh(myCompletionsProvider.future),
        child: AsyncBody<List<Completion>>(
          value: async,
          onRetry: () => ref.invalidate(myCompletionsProvider),
          builder: (all) {
            if (all.isEmpty) {
              return const EmptyState(
                icon: Icons.history_rounded,
                title: 'No history yet',
                message: 'Exercises you complete will be listed here.',
              );
            }
            final sorted = [...all]..sort((a, b) => b.completedAt.compareTo(a.completedAt));
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            final thisWeek = sorted.where((c) => c.completedAt.isAfter(weekAgo)).length;

            final groups = <DateTime, List<Completion>>{};
            for (final c in sorted) {
              groups.putIfAbsent(dayOnly(c.completedAt), () => []).add(c);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final s in [
                      ('${sorted.length}', 'Total completed'),
                      ('$thisWeek', 'Last 7 days'),
                    ])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: s.$2 == 'Total completed' ? 12 : 0),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.$1, style: text.headlineSmall),
                                Text(s.$2,
                                    style: text.bodySmall
                                        ?.copyWith(color: colors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                for (final entry in groups.entries) ...[
                  SectionHeader(fmtDateLong(entry.key)),
                  for (final c in entry.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(c.exerciseTitle, style: text.titleSmall)),
                                Text(fmtTime(c.completedAt),
                                    style: text.bodySmall
                                        ?.copyWith(color: colors.textSecondary)),
                              ],
                            ),
                            if (c.painLevel != null)
                              Text('Pain ${c.painLevel}/10',
                                  style: text.bodySmall
                                      ?.copyWith(color: colors.textSecondary)),
                            if ((c.patientNote ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(c.patientNote!, style: text.bodyMedium),
                            ],
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
