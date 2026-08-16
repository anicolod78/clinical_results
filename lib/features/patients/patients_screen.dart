/// Elenco dei pazienti e loro gestione.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../../core/db/database.dart';
import '../settings/settings_screen.dart';
import 'patient_detail_screen.dart';
import 'patient_form.dart';

class PatientsScreen extends ConsumerWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(patientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pazienti'),
        actions: [
          IconButton(
            tooltip: 'Blocca',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => ref.read(sessionProvider.notifier).lock(),
          ),
          IconButton(
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Nuovo paziente'),
      ),
      body: patients.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: '$e'),
        data: (list) => list.isEmpty
            ? const _EmptyPatients()
            : _PatientList(patients: list),
      ),
    );
  }

  static Future<void> _openForm(BuildContext context, {Patient? patient}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PatientForm(patient: patient),
    );
  }
}

class _PatientList extends ConsumerWidget {
  const _PatientList({required this.patients});

  final List<Patient> patients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: patients.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = patients[index];
        return ListTile(
          leading: CircleAvatar(child: Text(_initials(p.fullName))),
          title: Text(p.fullName),
          subtitle: Text(_subtitle(p)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ref.read(selectedPatientProvider.notifier).state = p.id;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PatientDetailScreen(patientId: p.id),
              ),
            );
          },
          onLongPress: () => PatientsScreen._openForm(context, patient: p),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  static String _subtitle(Patient p) {
    final bits = <String>[];
    if (p.birthDate != null) {
      bits.add(DateFormat('d MMMM y', 'it_IT').format(p.birthDate!));
    }
    if (p.fiscalCode != null && p.fiscalCode!.isNotEmpty) {
      bits.add(p.fiscalCode!);
    }
    return bits.isEmpty ? 'Nessun dato anagrafico' : bits.join(' · ');
  }
}

class _EmptyPatients extends StatelessWidget {
  const _EmptyPatients();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined,
                size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Nessun paziente', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Crea un profilo per iniziare ad archiviare i referti. '
              'Puoi averne più di uno, per esempio per i familiari.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
