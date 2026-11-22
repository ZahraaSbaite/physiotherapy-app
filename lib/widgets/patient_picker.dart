import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient.dart';
import '../services/patient_repository.dart';
import 'page_helpers.dart';

/// A checklist of the therapist's active patients.
class PatientPicker extends ConsumerWidget {
  const PatientPicker({super.key, required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody<List<Patient>>(
      value: ref.watch(patientsProvider),
      onRetry: () => ref.invalidate(patientsProvider),
      builder: (all) {
        final patients = all.where((p) => p.isActive || selected.contains(p.id)).toList();
        if (patients.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('You have no active patients yet.'),
          );
        }
        final allSelected = patients.every((p) => selected.contains(p.id));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${selected.length} selected',
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                TextButton(
                  onPressed: () => onChanged(
                      allSelected ? <String>{} : patients.map((p) => p.id).toSet()),
                  child: Text(allSelected ? 'Clear' : 'Select all'),
                ),
              ],
            ),
            for (final p in patients)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: selected.contains(p.id),
                title: Text(p.name),
                subtitle: p.isActive ? null : const Text('Deactivated'),
                onChanged: (on) {
                  final next = {...selected};
                  on == true ? next.add(p.id) : next.remove(p.id);
                  onChanged(next);
                },
              ),
          ],
        );
      },
    );
  }
}
