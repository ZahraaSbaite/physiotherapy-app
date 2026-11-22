import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/models/announcement.dart';
import 'package:physio_app/utils/formatters.dart';
import 'package:physio_app/widgets/app_card.dart';

import '../core/theme/app_colors.dart';
import '../models/patient.dart';
import '../services/announcement_repository.dart';
import '../services/patient_repository.dart';
import '../widgets/page_body.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

class BroadcastFormScreen extends ConsumerStatefulWidget {
  const BroadcastFormScreen({super.key, this.broadcastId});
  final String? broadcastId;

  @override
  ConsumerState<BroadcastFormScreen> createState() =>
      _BroadcastFormScreenState();
}

class _BroadcastFormScreenState
    extends ConsumerState<BroadcastFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _imageUrl = TextEditingController();
  String _audienceType = 'all';
  final Set<String> _selectedPatients = {};
  bool _saving = false;
  bool _prefilled = false;

  bool get _isEdit => widget.broadcastId != null;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _prefill(Broadcast b) {
    if (_prefilled) return;
    _prefilled = true;
    _title.text = b.title ?? '';
    _text.text = b.text;
    _imageUrl.text = b.imageUrl ?? '';
    _audienceType = b.audienceType;
    for (final r in b.recipients) {
      _selectedPatients.add(r.id);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audienceType == 'selected' && _selectedPatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one patient')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(announcementRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateBroadcast(
          widget.broadcastId!,
          title: _title.text.trim(),
          text: _text.text.trim(),
          imageUrl:
              _imageUrl.text.trim().isEmpty
                  ? null
                  : _imageUrl.text.trim(),
        );
      } else {
        await repo.createBroadcast(
          text: _text.text.trim(),
          title:
              _title.text.trim().isEmpty ? null : _title.text.trim(),
          imageUrl:
              _imageUrl.text.trim().isEmpty
                  ? null
                  : _imageUrl.text.trim(),
          audienceType: _audienceType,
          patientIds:
              _audienceType == 'selected'
                  ? _selectedPatients.toList()
                  : null,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Broadcast updated' : 'Broadcast sent',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit broadcast')),
        body: AsyncBody<Broadcast>(
          value: ref.watch(broadcastProvider(widget.broadcastId!)),
          onRetry:
              () => ref.invalidate(
                broadcastProvider(widget.broadcastId!),
              ),
          builder: (b) {
            _prefill(b);
            return _form();
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('New broadcast')),
      body: _form(),
    );
  }

  Widget _form() {
    final patients = ref.watch(patientsProvider);
    return SingleChildScrollView(
      child: PageBody(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _text,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Write a message first'
                              : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _audienceType,
                  decoration: const InputDecoration(
                    labelText: 'Audience',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All active patients'),
                    ),
                    DropdownMenuItem(
                      value: 'selected',
                      child: Text('Selected patients'),
                    ),
                  ],
                  onChanged:
                      (v) =>
                          setState(() => _audienceType = v ?? 'all'),
                ),
                if (_audienceType == 'selected') ...[
                  const SizedBox(height: 14),
                  patients.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(errorText(e)),
                    data: (List<Patient> all) {
                      final activePatients =
                          all.where((p) => p.isActive).toList();
                      return AppCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select patients',
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            for (final p in activePatients)
                              CheckboxListTile(
                                title: Text(p.name),
                                value: _selectedPatients.contains(
                                  p.id,
                                ),
                                onChanged:
                                    (v) => setState(() {
                                      if (v == true) {
                                        _selectedPatients.add(p.id);
                                      } else {
                                        _selectedPatients.remove(
                                          p.id,
                                        );
                                      }
                                    }),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child:
                      _saving
                          ? const ButtonSpinner()
                          : Text(
                            _isEdit
                                ? 'Save changes'
                                : 'Send broadcast',
                          ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
