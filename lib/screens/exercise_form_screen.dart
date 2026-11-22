import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/exercise.dart';
import '../services/exercise_repository.dart';
import '../utils/formatters.dart';
import '../widgets/page_body.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Therapist: create (exerciseId == null) or edit an exercise.
/// Media is stored as URLs; file upload needs a backend upload endpoint.
class ExerciseFormScreen extends ConsumerStatefulWidget {
  const ExerciseFormScreen({super.key, this.exerciseId});
  final String? exerciseId;

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _video = TextEditingController();
  final _images = TextEditingController(); // one link per line
  final _sets = TextEditingController();
  final _reps = TextEditingController();
  final _hold = TextEditingController();
  final _rest = TextEditingController();
  final _precautions = TextEditingController();
  bool _saving = false;
  bool _prefilled = false;

  bool get _isEdit => widget.exerciseId != null;

  @override
  void dispose() {
    for (final c in [_title, _category, _description, _video, _images, _precautions, _sets, _reps, _hold, _rest]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(Exercise e) {
    if (_prefilled) return;
    _prefilled = true;
    _title.text = e.title;
    _category.text = e.category ?? '';
    _description.text = e.description;
    _video.text = e.videoUrl ?? '';
    _images.text = e.imageUrls.join('\n');
    _sets.text = e.defaultSets?.toString() ?? '';
    _reps.text = e.defaultReps?.toString() ?? '';
    _hold.text = e.defaultDurationSeconds?.toString() ?? '';
    _rest.text = e.defaultRestSeconds?.toString() ?? '';
    _precautions.text = e.precautions ?? '';
  }

  String? _url(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    final uri = Uri.tryParse(s);
    return (uri != null && uri.hasScheme && uri.host.isNotEmpty)
        ? null
        : 'Enter a full link starting with https://';
  }

  String? _urls(String? v) {
    for (final line in (v ?? '').split('\n')) {
      final err = _url(line);
      if (err != null) return err;
    }
    return null;
  }

  String? _wholeNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    return (n == null || n < 0) ? 'Enter a whole number' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(exerciseRepositoryProvider);
    final exercise = Exercise(
      id: widget.exerciseId ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category.text.trim(),
      videoUrl: _video.text.trim(),
      imageUrls: _images.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList(),
      defaultSets: int.tryParse(_sets.text.trim()),
      defaultReps: int.tryParse(_reps.text.trim()),
      defaultDurationSeconds: int.tryParse(_hold.text.trim()),
      defaultRestSeconds: int.tryParse(_rest.text.trim()),
      precautions: _precautions.text.trim(),
    );
    try {
      if (_isEdit) {
        await repo.update(widget.exerciseId!, exercise);
        ref.invalidate(exerciseProvider(widget.exerciseId!));
      } else {
        await repo.create(exercise);
      }
      ref.invalidate(exercisesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Exercise updated' : 'Exercise created')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: const Text(
            'It will be removed from the library. Patients keep exercises already assigned to them.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(exerciseRepositoryProvider).delete(widget.exerciseId!);
      ref.invalidate(exercisesProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final async = ref.watch(exerciseProvider(widget.exerciseId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Edit exercise')),
        body: AsyncBody<Exercise>(
          value: async,
          onRetry: () => ref.invalidate(exerciseProvider(widget.exerciseId!)),
          builder: (e) {
            _prefill(e);
            return _form();
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('New exercise')), body: _form());
  }

  Widget _form() => SingleChildScrollView(
        child: PageBody(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Exercise name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _category,
                    decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                        hintText: 'e.g. Knee, Shoulder, Core'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 10,
                    decoration: const InputDecoration(
                        labelText: 'Instructions', alignLabelWithHint: true),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Describe how to do the exercise'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _precautions,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                        labelText: 'Precautions (optional)',
                        alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _video,
                    keyboardType: TextInputType.url,
                    decoration:
                        const InputDecoration(labelText: 'Video link (optional)'),
                    validator: _url,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _images,
                    keyboardType: TextInputType.multiline,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                        labelText: 'Image links (optional, one per line)',
                        alignLabelWithHint: true),
                    validator: _urls,
                  ),
                  const SectionHeader('Suggested prescription (optional)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sets,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sets'),
                          validator: _wholeNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _reps,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Reps'),
                          validator: _wholeNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hold,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Hold (seconds)'),
                          validator: _wholeNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _rest,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Rest (seconds)'),
                          validator: _wholeNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const ButtonSpinner()
                        : Text(_isEdit ? 'Save changes' : 'Create exercise'),
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 10),
                    TextButton(onPressed: _delete, child: const Text('Delete exercise')),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );
}
