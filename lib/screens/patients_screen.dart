import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/patient.dart';
import '../services/patient_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/page_body.dart';
import '../widgets/user_avatar.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

enum _StatusFilter { all, active, inactive }

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _search = TextEditingController();
  _StatusFilter _filter = _StatusFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Patient> _apply(List<Patient> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((p) {
      final matchesFilter = switch (_filter) {
        _StatusFilter.all => true,
        _StatusFilter.active => p.isActive,
        _StatusFilter.inactive => !p.isActive,
      };
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(patientsProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(
            tooltip: 'Exercise library',
            icon: const Icon(Icons.fitness_center_rounded),
            onPressed: () => context.push('/admin/exercises'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/patients/new'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New patient'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(patientsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageBody(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in _StatusFilter.values)
                        ChoiceChip(
                          label: Text(switch (f) {
                            _StatusFilter.all => 'All',
                            _StatusFilter.active => 'Active',
                            _StatusFilter.inactive => 'Inactive',
                          }),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  async.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorView(
                      message: e.toString().replaceFirst('Exception: ', ''),
                      onRetry: () => ref.invalidate(patientsProvider),
                    ),
                    data: (all) {
                      final items = _apply(all);
                      if (items.isEmpty) {
                        return EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: all.isEmpty
                              ? 'No patients yet'
                              : 'No matching patients',
                          message: all.isEmpty
                              ? 'Create a patient account to get started.'
                              : 'Try a different name or filter.',
                        );
                      }
                      return Column(
                        children: [
                          for (final p in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PatientCard(patient: p, textTheme: text),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.textTheme});
  final Patient patient;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      onTap: () => context.push('/admin/patients/${patient.id}'),
      child: Row(
        children: [
          UserAvatar(name: patient.name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  patient.email,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusChip(active: patient.isActive),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? colors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? colors.primary : colors.textSecondary,
            ),
      ),
    );
  }
}
