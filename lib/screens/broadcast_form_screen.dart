import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/announcement_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_states.dart';
import '../widgets/page_body.dart';
import '../widgets/page_helpers.dart';
import '../widgets/patient_picker.dart';

/// Therapist: send a one-way message to all patients or to selected ones.
class BroadcastFormScreen extends ConsumerStatefulWidget {
  const BroadcastFormScreen({super.key});

  @override
  ConsumerState<BroadcastFormScreen> createState() => _BroadcastFormScreenState();
}

class _BroadcastFormScreenState extends ConsumerState<BroadcastFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _text = TextEditingController();
  bool _toAll = true;
  Set<String> _selected = {};
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_toAll && _selected.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select at least one patient')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(announcementRepositoryProvider).sendBroadcast(
            title: _title.text.trim(),
            text: _text.text.trim(),
            toAll: _toAll,
            patientIds: _selected.toList(),
          );
      ref.invalidate(broadcastsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Announcement sent')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New broadcast')),
      body: SingleChildScrollView(
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
                    decoration: const InputDecoration(labelText: 'Title (optional)'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _text,
                    minLines: 4,
                    maxLines: 10,
                    maxLength: 4000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        labelText: 'Message', alignLabelWithHint: true),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Write a message' : null,
                  ),
                  const SectionHeader('Send to'),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All patients'),
                        selected: _toAll,
                        onSelected: (_) => setState(() => _toAll = true),
                      ),
                      ChoiceChip(
                        label: const Text('Selected patients'),
                        selected: !_toAll,
                        onSelected: (_) => setState(() => _toAll = false),
                      ),
                    ],
                  ),
                  if (!_toAll)
                    PatientPicker(
                      selected: _selected,
                      onChanged: (s) => setState(() => _selected = s),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending ? const ButtonSpinner() : const Text('Send'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
