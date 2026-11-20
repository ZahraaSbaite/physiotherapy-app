import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/exercise.dart';
import '../services/exercise_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/page_body.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Therapist: prescribe an exercise to one patient.
class AssignExerciseScreen extends ConsumerStatefulWidget {
  const AssignExerciseScreen({super.key, required this.patientId});
  final String patientId;

  @override
  ConsumerState<AssignExerciseScreen> createState() => _AssignExerciseScreenState();
}

class _AssignExerciseScreenState extends ConsumerState<AssignExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sets = TextEditingController(text: '3');
  final _reps = TextEditingController(text: '10');
  final _duration = TextEditingController();
  final _rest = TextEditingController(text: '30');
  final Set<int> _days = {1, 2, 3, 4, 5};
  Exercise? _exercise;
  DateTime _start = dayOnly(DateTime.now());
  DateTime? _end;
  bool _saving = false;
  String? _pickError;

  @override
  void dispose() {
    for (final c in [_sets, _reps, _duration, _rest]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExercise() async {
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ExercisePicker(),
    );
    if (picked != null) {
      setState(() {
        _exercise = picked;
        _pickError = null;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final today = dayOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : (_end ?? _start),
      firstDate: isStart ? today : _start,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(_start)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  String? _positive(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return (n == null || n < 1) ? 'Enter a number above 0' : null;
  }

  String? _optionalNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    return (n == null || n < 0) ? 'Enter a valid number' : null;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_exercise == null) setState(() => _pickError = 'Choose an exercise');
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }
    if (!valid || _exercise == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(exerciseRepositoryProvider).assign(
            widget.patientId,
            exerciseId: _exercise!.id,
            sets: int.parse(_sets.text.trim()),
            reps: int.parse(_reps.text.trim()),
            durationSeconds: int.tryParse(_duration.text.trim()),
            restSeconds: int.tryParse(_rest.text.trim()),
            daysOfWeek: _days.toList()..sort(),
            startDate: _start,
            endDate: _end,
          );
      ref.invalidate(patientAssignmentsProvider(widget.patientId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Exercise assigned')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Assign exercise')),
      body: SingleChildScrollView(
        child: PageBody(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    onTap: _pickExercise,
                    child: Row(
                      children: [
                        Icon(Icons.fitness_center_rounded, color: colors.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _exercise?.title ?? 'Choose an exercise',
                            style: text.titleSmall?.copyWith(
                                color: _exercise == null ? colors.textSecondary : null),
                          ),
                        ),
                        Icon(Icons.unfold_more_rounded, color: colors.textSecondary),
                      ],
                    ),
                  ),
                  if (_pickError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(_pickError!,
                          style: text.bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.error)),
                    ),
                  const SectionHeader('Prescription'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sets,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sets'),
                          validator: _positive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _reps,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Reps'),
                          validator: _positive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _duration,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Hold (seconds)', hintText: 'Optional'),
                          validator: _optionalNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _rest,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Rest (seconds)', hintText: 'Optional'),
                          validator: _optionalNumber,
                        ),
                      ),
                    ],
                  ),
                  const SectionHeader('Schedule'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          label: Text(weekdayShort(d)),
                          selected: _days.contains(d),
                          onSelected: (on) =>
                              setState(() => on ? _days.add(d) : _days.remove(d)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: true),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Starts'),
                            child: Text(fmtDate(_start)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: false),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Ends',
                              suffixIcon: _end == null
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      onPressed: () => setState(() => _end = null),
                                    ),
                            ),
                            child: Text(_end == null ? 'No end date' : fmtDate(_end!)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const ButtonSpinner()
                        : const Text('Assign exercise'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExercisePicker extends ConsumerWidget {
  const _ExercisePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exercisesProvider);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: AsyncBody<List<Exercise>>(
        value: async,
        onRetry: () => ref.invalidate(exercisesProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No exercises yet',
              message: 'Add exercises to the library first.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => AppCard(
              onTap: () => Navigator.pop(context, items[i]),
              child: Text(items[i].title, style: Theme.of(context).textTheme.titleSmall),
            ),
          );
        },
      ),
    );
  }
}
