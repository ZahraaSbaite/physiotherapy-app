import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/formatters.dart';
import 'app_states.dart';
import 'page_body.dart';

/// Renders loading / error / data for an AsyncValue using the app's states.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: errorText(e), onRetry: onRetry),
        data: builder,
      );
}

/// Pull-to-refresh, scrolling and constrained width for a page.
class RefreshPage extends StatelessWidget {
  const RefreshPage({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageBody(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              child: child,
            ),
          ),
        ),
      );
}

/// Section heading. Replace with the project's SectionTitle if preferred.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}


/// Centered spinner for loading content.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
}

/// Error state with a retry button, built on the shared EmptyState.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Couldn’t load this',
        message: message,
        isError: true,
        action: onRetry == null
            ? null
            : OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      );
}
