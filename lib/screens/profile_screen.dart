import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../services/api_exception.dart';
import '../utils/validators.dart';
import '../services/auth_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/app_states.dart';
import '../widgets/app_tile.dart';
import '../widgets/home_widgets.dart';
import '../widgets/page_body.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    required this.changePasswordPath,
    required this.settingsPath,
  });

  final String changePasswordPath;
  final String settingsPath;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final repo = ref.read(authRepositoryProvider);
    final notifier = ref.read(authControllerProvider.notifier);

    setState(() => _saving = true);
    try {
      final updated = await repo.updateProfile({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
      });
      notifier.setUser(updated);
      if (mounted) _snack('Profile saved');
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text('You will need to log in again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ctx.appColors.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Log out'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final text = Theme.of(context).textTheme;
    final c = context.appColors;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            Center(child: UserAvatar(name: user.name, size: 88)),
            const SizedBox(height: AppSpacing.lg),
            if (user.name.isNotEmpty)
              Text(
                user.name,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              user.email,
              style: text.bodyMedium?.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AppPill(user.isAdmin ? 'Therapist (admin)' : 'Patient'),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle('Personal information'),
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      enabled: !_saving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _phone,
                      enabled: !_saving,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving ? const ButtonSpinner() : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle('Account'),
            Column(
              spacing: AppSpacing.md,
              children: [
                AppCard(
                  onTap: () => context.push(widget.settingsPath),
                  child: const AppTile(
                    icon: Icons.tune_outlined,
                    title: 'Settings',
                    subtitle: 'Appearance',
                    trailing: TileChevron(),
                  ),
                ),
                AppCard(
                  onTap: () => context.push(widget.changePasswordPath),
                  child: const AppTile(
                    icon: Icons.lock_outline,
                    title: 'Change password',
                    trailing: TileChevron(),
                  ),
                ),
                AppCard(
                  onTap: _confirmLogout,
                  child: const AppTile(
                    icon: Icons.logout_outlined,
                    title: 'Log out',
                    destructive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
