import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../services/auth_controller.dart';
import '../widgets/appear_animation.dart';
import '../widgets/home_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/placeholders.dart';

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
              AppearAnimation(child: HomeHeader(name: user?.name ?? '')),
              const SizedBox(height: AppSpacing.xxl),
              const AppearAnimation(index: 1, child: SectionTitle('Today')),
              const AppearAnimation(
                index: 2,
                child: ComingSoonCard(
                  icon: Icons.fitness_center_outlined,
                  title: "Today's exercises",
                  subtitle: 'The exercises to do today, with a check when done.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppearAnimation(
                index: 3,
                child: ComingSoonCard(
                  icon: Icons.event_outlined,
                  title: 'Next appointment',
                  subtitle: 'Your next session with your therapist.',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AppearAnimation(
                index: 4,
                child: SectionTitle('From your therapist'),
              ),
              const AppearAnimation(
                index: 5,
                child: ComingSoonCard(
                  icon: Icons.campaign_outlined,
                  title: 'Announcements',
                  subtitle: 'Broadcasts and channels from your therapist.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
