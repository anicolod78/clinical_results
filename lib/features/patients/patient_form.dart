/// Creazione e modifica di un paziente.
library;

// `Value` distingue "campo non modificato" da "campo azzerato": senza di essa
// non si potrebbe cancellare un codice fiscale inserito per errore.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';

class PatientForm extends ConsumerStatefulWidget {
  const PatientForm({super.key, this.patient});

  final Patient? patient;

  @override
  ConsumerState<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends ConsumerState<PatientForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _fiscalCode;
  DateTime? _birthDate;
  String? _sex;

  bool get _isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.patient?.fullName ?? '');
    _fiscalCode = TextEditingController(text: widget.patient?.fiscalCode ?? '');
    _birthDate = widget.patient?.birthDate;
    _sex = widget.patient?.sex;
  }

  @override
  void dispose() {
    _name.dispose();
    _fiscalCode.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 40),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Data di nascita',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(patientRepositoryProvider);
    final code = _fiscalCode.text.trim().toUpperCase();

    if (_isEditing) {
      await repo.update(
        widget.patient!.copyWith(
          fullName: _name.text.trim(),
          fiscalCode: Value(code.isEmpty ? null : code),
          birthDate: Value(_birthDate),
          sex: Value(_sex),
        ),
      );
    } else {
      await repo.create(
        fullName: _name.text.trim(),
        fiscalCode: code.isEmpty ? null : code,
        birthDate: _birthDate,
        sex: _sex,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare il paziente?'),
        content: Text(
          'Verranno eliminati anche tutti i referti e i valori di '
          '${widget.patient!.fullName}. L operazione non è reversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(patientRepositoryProvider).delete(widget.patient!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Due margini distinti da sommare: la tastiera quando è aperta, e la
    // barra di navigazione di sistema. Tenendo conto solo della prima, il
    // pulsante di conferma finiva sotto la barra e non era raggiungibile.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard + systemBar),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Modifica paziente' : 'Nuovo paziente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome e cognome',
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Indica un nome'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fiscalCode,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16),
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Codice fiscale (facoltativo)',
                  helperText: 'Permette di riconoscere il paziente '
                      'automaticamente sui referti',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null;
                  return t.length == 16 ? null : 'Servono 16 caratteri';
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickBirthDate,
                      icon: const Icon(Icons.cake_outlined),
                      label: Text(
                        _birthDate == null
                            ? 'Data di nascita'
                            : DateFormat('d MMM y', 'it_IT')
                                  .format(_birthDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String?>(
                    segments: const [
                      ButtonSegment(value: 'M', label: Text('M')),
                      ButtonSegment(value: 'F', label: Text('F')),
                    ],
                    selected: {_sex},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (s) =>
                        setState(() => _sex = s.isEmpty ? null : s.first),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Salva' : 'Crea paziente'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Elimina paziente'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
