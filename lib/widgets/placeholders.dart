import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_states.dart';
import 'app_tile.dart';

/// A tab for a feature that is not built yet.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(icon: icon, title: 'Coming soon', message: message),
    );
  }
}

/// A card on a home screen for a feature that is not built yet.
class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: AppTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: const AppPill('Soon'),
      ),
    );
  }
}
