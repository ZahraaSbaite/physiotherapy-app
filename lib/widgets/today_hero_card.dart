import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/exercise.dart';
import '../services/exercise_repository.dart';

/// The one prominent card on the patient home screen: today's progress with a
/// ring, the next exercise, and a button to start it.
class TodayHeroCard extends ConsumerWidget {
  const TodayHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayAssignmentsProvider);

    return async.when(
      loading:
          () => const _HeroShell(
            child: _HeroMessage(
              title: "Today's exercises",
              message: 'Loading your plan...',
            ),
          ),
      error:
          (error, stack) => _HeroShell(
            child: _HeroMessage(
              title: "Today's exercises",
              message: "Couldn't load today's plan.",
              action: TextButton(
                onPressed: () => ref.invalidate(todayAssignmentsProvider),
                style: TextButton.styleFrom(
                  foregroundColor: context.appColors.onHero,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Try again'),
              ),
            ),
          ),
      data: (items) => _HeroContent(items: items),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.items});

  final List<ExerciseAssignment> items;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return _HeroShell(
        onTap: () => context.go('/patient/exercises'),
        child: const _HeroMessage(
          title: "Today's exercises",
          message: 'Nothing scheduled today. Enjoy the rest.',
        ),
      );
    }

    final remaining = items.where((a) => !a.completed).toList();
    final next = remaining.isEmpty ? null : remaining.first;
    final total = items.length;
    final done = total - remaining.length;

    final muted = c.onHero.withValues(alpha: 0.78);

    return _HeroShell(
      onTap: () => context.go('/patient/exercises'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's exercises",
                      style: text.titleMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      next == null ? 'All done for today' : '${total - done} to go',
                      style: text.headlineMedium?.copyWith(color: c.onHero),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next == null
                          ? 'Nice work. Rest up.'
                          : 'Next: ${next.exercise.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              _ProgressRing(done: done, total: total),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/patient/exercises/${next.id}'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(done == 0 ? 'Start' : 'Continue'),
              style: FilledButton.styleFrom(
                backgroundColor: c.highlight,
                foregroundColor: c.onHighlight,
                minimumSize: const Size(0, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroShell extends StatelessWidget {
  const _HeroShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: c.hero,
      borderRadius: BorderRadius.circular(AppRadius.sheet),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: c.onHero.withValues(alpha: 0.08),
        highlightColor: c.onHero.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class _HeroMessage extends StatelessWidget {
  const _HeroMessage({required this.title, required this.message, this.action});

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.titleMedium?.copyWith(
            color: c.onHero.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 6),
        Text(message, style: text.titleLarge?.copyWith(color: c.onHero)),
        if (action != null) ...[const SizedBox(height: AppSpacing.sm), action!],
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final value = total == 0 ? 0.0 : done / total;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: '$done of $total exercises completed',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
        curve: AppMotion.curve,
        builder: (context, progress, _) {
          return SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                trackColor: c.onHero.withValues(alpha: 0.18),
                arcColor: c.highlight,
              ),
              child: Center(
                child: Text(
                  '$done/$total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: c.onHero,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
  });

  final double progress;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final arcRect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawCircle(
      arcRect.center,
      arcRect.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = trackColor,
    );

    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = arcColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.arcColor != arcColor;
}
