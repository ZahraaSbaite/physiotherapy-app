import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../services/api_exception.dart';
import '../services/auth_controller.dart';
import '../utils/validators.dart';
import '../widgets/app_states.dart';

class TherapistRegisterScreen extends ConsumerStatefulWidget {
  const TherapistRegisterScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<TherapistRegisterScreen> createState() =>
      _TherapistRegisterScreenState();
}

class _TherapistRegisterScreenState
    extends ConsumerState<TherapistRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _fullName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Replace with your actual therapist registration method on AuthController
      await ref
          .read(authControllerProvider.notifier)
          .registerTherapist(
            fullName: _fullName.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      // If registration automatically signs in and your root router reacts to
      // auth state changes, pop back to root so the home screen shows cleanly.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Could not create account. Please try again.',
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Therapist Sign Up')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create therapist account',
                        style: text.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Set up your iPhysio clinician profile to manage patients.',
                        style: text.bodyLarge?.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      TextFormField(
                        controller: _fullName,
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        enabled: !_loading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Work email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !_loading,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.newPassword,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip:
                                _obscure
                                    ? 'Show password'
                                    : 'Hide password',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscure = !_obscure,
                                ),
                          ),
                        ),
                        validator: Validators.passwordRequired,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPassword,
                        enabled: !_loading,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value != _password.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      AnimatedSize(
                        duration: AppMotion.fast,
                        curve: AppMotion.curve,
                        alignment: Alignment.topCenter,
                        child:
                            _error == null
                                ? const SizedBox(
                                  width: double.infinity,
                                )
                                : Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                  ),
                                  child: ErrorBanner(_error!),
                                ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _register,
                        child:
                            _loading
                                ? const ButtonSpinner()
                                : const Text(
                                  'Create therapist account',
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
