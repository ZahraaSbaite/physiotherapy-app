import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/app_user.dart';
import '../services/auth_controller.dart';
import 'user_avatar.dart';

class _DrawerDestination {
  const _DrawerDestination({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

/// Role-aware iPhysio navigation drawer.
///
/// Destinations intentionally use routes that already exist in app_router.dart.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  List<_DrawerDestination> _destinations(AppUser user) {
    if (user.isAdmin) {
      return const [
        _DrawerDestination(
          label: 'Dashboard',
          icon: Icons.home_outlined,
          path: '/admin',
        ),
        _DrawerDestination(
          label: 'Patients',
          icon: Icons.people_outline,
          path: '/admin/patients',
        ),
        _DrawerDestination(
          label: 'Appointments',
          icon: Icons.calendar_month_outlined,
          path: '/admin/calendar',
        ),
        _DrawerDestination(
          label: 'Profile',
          icon: Icons.person_outline,
          path: '/admin/profile',
        ),
        _DrawerDestination(
          label: 'Settings',
          icon: Icons.tune_outlined,
          path: '/admin/profile/settings',
        ),
      ];
    }

    return const [
      _DrawerDestination(
        label: 'Dashboard',
        icon: Icons.home_outlined,
        path: '/patient',
      ),
      _DrawerDestination(
        label: 'My Exercises',
        icon: Icons.fitness_center_outlined,
        path: '/patient/exercises',
      ),
      _DrawerDestination(
        label: 'My Appointments',
        icon: Icons.event_outlined,
        path: '/patient/appointments',
      ),
      _DrawerDestination(
        label: 'Profile',
        icon: Icons.person_outline,
        path: '/patient/profile',
      ),
      _DrawerDestination(
        label: 'Settings',
        icon: Icons.tune_outlined,
        path: '/patient/profile/settings',
      ),
    ];
  }

  bool _isSelected(String currentPath, String destinationPath) {
    if (destinationPath.endsWith('/profile')) {
      return currentPath == destinationPath ||
          currentPath.startsWith('$destinationPath/');
    }
    return currentPath == destinationPath;
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.appColors.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final colors = context.appColors;
    final currentPath = GoRouterState.of(context).uri.path;

    if (user == null) return const SizedBox.shrink();

    final destinations = _destinations(user);

    return Drawer(
      width: 304,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 18, 20),
              child: Row(
                children: [
                  UserAvatar(name: user.name, size: 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? 'iPhysio user' : user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          user.isAdmin ? 'Therapist' : 'Patient',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'MENU',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final destination in destinations)
                    _DrawerTile(
                      destination: destination,
                      selected: _isSelected(currentPath, destination.path),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentPath != destination.path) {
                          context.go(destination.path);
                        }
                      },
                    ),
                ],
              ),
            ),
            Divider(color: colors.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: _DrawerTile(
                destination: const _DrawerDestination(
                  label: 'Log out',
                  icon: Icons.logout_outlined,
                  path: '',
                ),
                destructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  _logout(context, ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.destination,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final _DrawerDestination destination;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = destructive
        ? colors.error
        : selected
            ? colors.primary
            : colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? colors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(destination.icon, size: 21, color: foreground),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destination.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: selected || destructive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                  ),
                ),
                if (selected)
                  Icon(Icons.circle, size: 7, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
