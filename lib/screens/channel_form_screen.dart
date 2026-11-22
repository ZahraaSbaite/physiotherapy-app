import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/announcement.dart';
import '../services/announcement_repository.dart';
import '../utils/formatters.dart';
import '../widgets/app_states.dart';
import '../widgets/page_body.dart';
import '../widgets/page_helpers.dart';
import '../widgets/patient_picker.dart';

/// Therapist: create (channelId == null) or edit a channel.
class ChannelFormScreen extends ConsumerStatefulWidget {
  const ChannelFormScreen({super.key, this.channelId});
  final String? channelId;

  @override
  ConsumerState<ChannelFormScreen> createState() => _ChannelFormScreenState();
}

class _ChannelFormScreenState extends ConsumerState<ChannelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _membersCanReply = false;
  Set<String> _members = {};
  bool _saving = false;
  bool _prefilled = false;

  bool get _isEdit => widget.channelId != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _prefill(Channel c) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = c.name;
    _description.text = c.description ?? '';
    _membersCanReply = c.membersCanReply;
    _members = c.members.map((m) => m.id).toSet();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(announcementRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateChannel(widget.channelId!, {
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'membersCanReply': _membersCanReply,
          'memberIds': _members.toList(),
        });
        ref.invalidate(channelProvider(widget.channelId!));
      } else {
        await repo.createChannel(
          name: _name.text.trim(),
          description: _description.text.trim(),
          memberIds: _members.toList(),
          membersCanReply: _membersCanReply,
        );
      }
      ref.invalidate(channelsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Channel updated' : 'Channel created')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _archive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive channel?'),
        content: const Text('Members will no longer see it. Its messages are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Archive')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(announcementRepositoryProvider)
          .updateChannel(widget.channelId!, {'isArchived': true});
      ref.invalidate(channelsProvider);
      if (mounted) context.go('/admin/announcements');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final id = widget.channelId!;
      return Scaffold(
        appBar: AppBar(title: const Text('Edit channel')),
        body: AsyncBody<Channel>(
          value: ref.watch(channelProvider(id)),
          onRetry: () => ref.invalidate(channelProvider(id)),
          builder: (c) {
            _prefill(c);
            return _form();
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('New channel')), body: _form());
  }

  Widget _form() => SingleChildScrollView(
        child: PageBody(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Channel name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Description (optional)', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _membersCanReply,
                    onChanged: (v) => setState(() => _membersCanReply = v),
                    title: const Text('Members can reply'),
                    subtitle: const Text(
                        'Replies are visible to everyone in the channel. Leave off for one-way posts.'),
                  ),
                  const SectionHeader('Members'),
                  PatientPicker(
                    selected: _members,
                    onChanged: (s) => setState(() => _members = s),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const ButtonSpinner()
                        : Text(_isEdit ? 'Save changes' : 'Create channel'),
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 10),
                    TextButton(onPressed: _archive, child: const Text('Archive channel')),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );
}
