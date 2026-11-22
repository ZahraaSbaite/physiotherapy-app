import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/appointment.dart';
import '../models/exercise.dart';
import '../services/appointment_repository.dart';
import '../services/exercise_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/page_body.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Therapist: prescribe an exercise to one patient.
/// Every assignment is linked to an appointment, has a number of sessions
/// (totalTimes), a repeat rule and optional reminder times.
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
  final _total = TextEditingController(text: '10');
  final _instructions = TextEditingController();
  final Set<int> _days = {1, 2, 3, 4, 5}; // Monday = 1 ... Sunday = 7
  final List<String> _times = []; // "HH:MM"
  RepeatType _repeat = RepeatType.daily;
  Exercise? _exercise;
  String? _appointmentId;
  String? _nextId;
  DateTime _start = dayOnly(DateTime.now());
  late DateTime _end = _start.add(const Duration(days: 13));
  bool _saving = false;
  String? _pickError;

  @override
  void dispose() {
    for (final c in [_sets, _reps, _duration, _rest, _total, _instructions]) {
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
        // Start from the exercise's suggested prescription
        if (picked.defaultSets != null) _sets.text = '${picked.defaultSets}';
        if (picked.defaultReps != null) _reps.text = '${picked.defaultReps}';
        if (picked.defaultDurationSeconds != null) {
          _duration.text = '${picked.defaultDurationSeconds}';
        }
        if (picked.defaultRestSeconds != null) _rest.text = '${picked.defaultRestSeconds}';
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final today = dayOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: isStart ? today : _start,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked == null) return;
    final value = '${two(picked.hour)}:${two(picked.minute)}';
    if (_times.contains(value) || _times.length >= 6) return;
    setState(() => _times
      ..add(value)
      ..sort());
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

  String _appointmentLabel(Appointment a) {
    final base = '${fmtDateLong(a.start)} · ${fmtTime(a.start)}';
    return a.status == AppointmentStatus.scheduled ? base : '$base (${a.status.label})';
  }

  /// The appointment closest to now is the most likely one to link.
  String? _defaultAppointment(List<Appointment> all) {
    if (all.isEmpty) return null;
    final now = DateTime.now();
    final sorted = [...all]..sort((a, b) =>
        a.start.difference(now).abs().compareTo(b.start.difference(now).abs()));
    return sorted.first.id;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_exercise == null) setState(() => _pickError = 'Choose an exercise');
    if (_repeat == RepeatType.weekly && _days.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }
    if (!valid || _exercise == null || _appointmentId == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(exerciseRepositoryProvider).assign(
            widget.patientId,
            exerciseId: _exercise!.id,
            appointmentId: _appointmentId!,
            nextAppointmentId: _nextId,
            sets: int.tryParse(_sets.text.trim()),
            reps: int.tryParse(_reps.text.trim()),
            durationSeconds: int.tryParse(_duration.text.trim()),
            restSeconds: int.tryParse(_rest.text.trim()),
            instructions: _instructions.text.trim(),
            startDate: _start,
            endDate: _end,
            totalTimes: int.parse(_total.text.trim()),
            repeatType: _repeat,
            daysOfWeek: _days.toList(),
            reminderTimes: _times,
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

  Widget _appointmentSection(AsyncValue<List<Appointment>> async) {
    return AsyncBody<List<Appointment>>(
      value: async,
      onRetry: () => ref.invalidate(patientAppointmentsProvider(widget.patientId)),
      builder: (all) {
        if (all.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                  'Exercises are linked to an appointment. Schedule one for this patient first.'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.push('/admin/appointments/new');
                  ref.invalidate(patientAppointmentsProvider(widget.patientId));
                },
                icon: const Icon(Icons.event_rounded),
                label: const Text('Schedule appointment'),
              ),
            ],
          );
        }
        _appointmentId ??= _defaultAppointment(all);
        final chosen = all.where((a) => a.id == _appointmentId).firstOrNull;
        final later = chosen == null
            ? <Appointment>[]
            : all
                .where((a) =>
                    a.start.isAfter(chosen.start) &&
                    a.status == AppointmentStatus.scheduled)
                .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _appointmentId,
              decoration: const InputDecoration(labelText: 'Prescribed at appointment'),
              items: [
                for (final a in all)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(_appointmentLabel(a), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                _appointmentId = v;
                _nextId = null;
              }),
              validator: (v) => v == null ? 'Choose an appointment' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              key: ValueKey(_appointmentId),
              isExpanded: true,
              initialValue: _nextId,
              decoration: const InputDecoration(labelText: 'Until next appointment (optional)'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Not linked')),
                for (final a in later)
                  DropdownMenuItem<String?>(
                    value: a.id,
                    child: Text(_appointmentLabel(a), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                _nextId = v;
                final next = all.where((a) => a.id == v).firstOrNull;
                if (next != null && !dayOnly(next.start).isBefore(_start)) {
                  _end = dayOnly(next.start);
                }
              }),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final appointments = ref.watch(patientAppointmentsProvider(widget.patientId));

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
                  const SectionHeader('Appointment'),
                  _appointmentSection(appointments),
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _instructions,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Notes for the patient (optional)',
                        alignLabelWithHint: true),
                  ),
                  const SectionHeader('Schedule'),
                  TextFormField(
                    controller: _total,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Total sessions', helperText: 'For example 10 sessions'),
                    validator: _positive,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in RepeatType.values)
                        ChoiceChip(
                          label: Text(t.label),
                          selected: _repeat == t,
                          onSelected: (_) => setState(() => _repeat = t),
                        ),
                    ],
                  ),
                  if (_repeat == RepeatType.weekly) ...[
                    const SizedBox(height: 12),
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
                  ],
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
                            decoration: const InputDecoration(labelText: 'Ends'),
                            child: Text(fmtDate(_end)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SectionHeader('Reminders (optional)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in _times)
                        InputChip(
                          label: Text(t),
                          onDeleted: () => setState(() => _times.remove(t)),
                        ),
                      if (_times.length < 6)
                        ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add time'),
                          onPressed: _addTime,
                        ),
                    ],
                  ),
                  if (_times.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'With ${_times.length} reminder times, the exercise is done ${_times.length} times a day.',
                        style: text.bodySmall?.copyWith(color: colors.textSecondary),
                      ),
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
