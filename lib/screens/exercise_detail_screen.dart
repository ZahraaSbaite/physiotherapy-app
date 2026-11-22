import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../models/exercise.dart';
import '../services/exercise_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/page_helpers.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.assignmentId});
  final String assignmentId;

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    ExerciseAssignment a,
  ) async {
    final result = await showModalBottomSheet<
      ({int? pain, String notes, String? scheduledTime})
    >(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FeedbackSheet(reminderTimes: a.reminderTimes),
    );
    if (result == null) return;

    try {
      await ref
          .read(exerciseRepositoryProvider)
          .complete(
            assignmentId,
            painLevel: result.pain,
            patientNote: result.notes,
            scheduledTime: result.scheduledTime,
          );
      ref.invalidate(myAssignmentProvider(assignmentId));
      ref.invalidate(todayAssignmentsProvider);
      ref.invalidate(myCompletionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise completed. Well done.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final async = ref.watch(myAssignmentProvider(assignmentId));

    Widget chip(String label) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: text.labelMedium?.copyWith(color: colors.primary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: RefreshPage(
        onRefresh:
            () async => ref.refresh(
              myAssignmentProvider(assignmentId).future,
            ),
        child: AsyncBody<ExerciseAssignment>(
          value: async,
          onRetry:
              () =>
                  ref.invalidate(myAssignmentProvider(assignmentId)),
          builder: (a) {
            final ex = a.exercise;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ex.imageUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: ex.imageUrls.length,
                        separatorBuilder:
                            (_, __) => const SizedBox(width: 10),
                        itemBuilder:
                            (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                ex.imageUrls[i],
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        const SizedBox.shrink(),
                              ),
                            ),
                      ),
                    ),
                  ),
                Text(ex.title, style: text.headlineSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (a.sets != null) chip('${a.sets} sets'),
                    if (a.reps != null) chip('${a.reps} reps'),
                    if (a.durationSeconds != null &&
                        a.durationSeconds! > 0)
                      chip('Hold ${fmtSeconds(a.durationSeconds!)}'),
                    if (a.restSeconds != null && a.restSeconds! > 0)
                      chip('Rest ${fmtSeconds(a.restSeconds!)}'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${a.doneCount}/${a.totalTimes} sessions done',
                  style: text.titleSmall?.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: a.progress,
                    minHeight: 8,
                    backgroundColor: colors.secondary,
                    color: colors.primary,
                  ),
                ),
                if ((a.instructions ?? '').isNotEmpty) ...[
                  const SectionHeader('From your therapist'),
                  AppCard(
                    child: Text(
                      a.instructions!,
                      style: text.bodyMedium,
                    ),
                  ),
                ],
                const SectionHeader('Instructions'),
                AppCard(
                  child: Text(ex.description, style: text.bodyMedium),
                ),
                if ((ex.precautions ?? '').isNotEmpty) ...[
                  const SectionHeader('Precautions'),
                  AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ex.precautions!,
                            style: text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if ((ex.videoUrl ?? '').isNotEmpty) ...[
                  const SectionHeader('Video'),
                  AppCard(
                    onTap: () async {
                      final uri = Uri.parse(ex.videoUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        await Clipboard.setData(
                          ClipboardData(text: ex.videoUrl!),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open video. Link copied to clipboard.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Watch video',
                            style: text.titleSmall,
                          ),
                        ),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed:
                      a.completed
                          ? null
                          : () => _complete(context, ref, a),
                  icon: Icon(
                    a.completed
                        ? Icons.check_circle_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    a.completed
                        ? 'Completed today'
                        : 'Mark as completed',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({required this.reminderTimes});
  final List<String> reminderTimes;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _notes = TextEditingController();
  double? _pain;
  String? _scheduledTime;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How did it feel?', style: text.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _pain == null
                      ? 'Pain level (optional)'
                      : 'Pain level: ${_pain!.round()} / 10',
                  style: text.titleSmall,
                ),
              ),
              if (_pain != null)
                TextButton(
                  onPressed: () => setState(() => _pain = null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          Text(
            '0 means no pain, 10 means the worst pain. You can skip this.',
            style: text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          Slider(
            value: _pain ?? 0,
            min: 0,
            max: 10,
            divisions: 10,
            label: (_pain ?? 0).round().toString(),
            onChanged: (v) => setState(() => _pain = v),
          ),
          if (widget.reminderTimes.length > 1) ...[
            const SizedBox(height: 16),
            Text('Which session?', style: text.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.reminderTimes.map((time) {
                    final isSelected = _scheduledTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      onSelected:
                          (selected) => setState(
                            () =>
                                _scheduledTime =
                                    selected ? time : null,
                          ),
                      selectedColor: colors.highlightSoft,
                      checkmarkColor: colors.highlight,
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? colors.highlight
                                : colors.textPrimary,
                        fontWeight:
                            isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                      ),
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes for your therapist (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed:
                () => Navigator.pop(context, (
                  pain: _pain?.round(),
                  notes: _notes.text.trim(),
                  scheduledTime: _scheduledTime,
                )),
            child: const Text('Save and complete'),
          ),
        ],
      ),
    );
  }
}
