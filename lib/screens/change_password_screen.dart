import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../services/api_exception.dart';
import '../utils/validators.dart';
import '../services/auth_controller.dart';
import '../widgets/app_states.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(authRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await repo.changePassword(_current.text, _new.text);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Password changed')));
      if (mounted) {
        context.pop();
      }
      return;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration field(String label) => InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show passwords' : 'Hide passwords',
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _current,
                      enabled: !_loading,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: field('Current password'),
                      validator: Validators.passwordRequired,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _new,
                      enabled: !_loading,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: field('New password (min 8 characters)'),
                      validator: Validators.newPassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      enabled: !_loading,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: field('Repeat new password'),
                      validator:
                          (v) =>
                              v != _new.text ? 'Passwords do not match' : null,
                    ),
                    AnimatedSize(
                      duration: AppMotion.fast,
                      curve: AppMotion.curve,
                      alignment: Alignment.topCenter,
                      child:
                          _error == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ErrorBanner(_error!),
                              ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child:
                          _loading
                              ? const ButtonSpinner()
                              : const Text('Change password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
