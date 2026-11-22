import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../services/auth_controller.dart';
import '../widgets/app_states.dart';
import '../widgets/brand_mark.dart';

/// Shown while the app checks the saved login at launch.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(authControllerProvider).restoreError;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child:
            error == null
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(size: 72),
                      const SizedBox(height: AppSpacing.xl),
                      Text('iPhysio', style: text.headlineSmall),
                      const SizedBox(height: AppSpacing.xxl),
                      const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ],
                  ),
                )
                : EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Connection problem',
                  message: error,
                  isError: true,
                  action: SizedBox(
                    width: 200,
                    child: FilledButton(
                      onPressed:
                          () =>
                              ref
                                  .read(authControllerProvider.notifier)
                                  .restore(),
                      child: const Text('Retry'),
                    ),
                  ),
                ),
      ),
    );
  }
}
