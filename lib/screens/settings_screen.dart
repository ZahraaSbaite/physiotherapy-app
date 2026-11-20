import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/home_widgets.dart';
import '../widgets/page_body.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            const SectionTitle('Appearance'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose how iPhysio looks. System follows your device.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedButton<ThemeMode>(
                    expandedInsets: EdgeInsets.zero,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('System'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged:
                        (selection) => ref
                            .read(themeModeProvider.notifier)
                            .setMode(selection.first),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
