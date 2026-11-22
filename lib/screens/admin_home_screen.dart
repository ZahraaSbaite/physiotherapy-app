import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../services/auth_controller.dart';
import '../widgets/announcements_preview.dart';
import '../widgets/appear_animation.dart';
import '../widgets/home_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/placeholders.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

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
              AppearAnimation(
                child: HomeHeader(name: user?.name ?? ''),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const AppearAnimation(
                index: 1,
                child: SectionTitle('Today'),
              ),
              const AppearAnimation(
                index: 2,
                child: ComingSoonCard(
                  icon: Icons.today_outlined,
                  title: "Today's schedule",
                  subtitle:
                      'Your appointments for today will appear here.',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AppearAnimation(
                index: 3,
                child: SectionTitle('Your patients'),
              ),
              const AppearAnimation(index: 3, child: AdminAnnouncementsCard()),
              const SizedBox(height: AppSpacing.md),
              const AppearAnimation(
                index: 4,
                child: ComingSoonCard(
                  icon: Icons.note_alt_outlined,
                  title: 'Patient notes',
                  subtitle:
                      'New notes from exercises your patients completed.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
