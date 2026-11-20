import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/exercise.dart';
import '../services/exercise_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Therapist: exercise library.
class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(exercisesProvider);
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/exercises/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New exercise'),
      ),
      body: RefreshPage(
        onRefresh: () async => ref.refresh(exercisesProvider.future),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search exercises',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            AsyncBody<List<Exercise>>(
              value: async,
              onRetry: () => ref.invalidate(exercisesProvider),
              builder: (all) {
                final q = _search.text.trim().toLowerCase();
                final items = all
                    .where((e) =>
                        q.isEmpty ||
                        e.title.toLowerCase().contains(q) ||
                        (e.category ?? '').toLowerCase().contains(q))
                    .toList();
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: all.isEmpty ? 'No exercises yet' : 'No matching exercises',
                    message: all.isEmpty
                        ? 'Create your first exercise to start building programs.'
                        : 'Try a different search.',
                  );
                }
                return Column(
                  children: [
                    for (final e in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: () =>
                              context.push('/admin/exercises/${e.id}/edit'),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.fitness_center_rounded,
                                    color: colors.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title, style: text.titleMedium),
                                    if ((e.category ?? '').isNotEmpty)
                                      Text(e.category!,
                                          style: text.bodySmall?.copyWith(
                                              color: colors.textSecondary)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: colors.textSecondary),
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
