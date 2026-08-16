/// Revisione dei valori estratti, prima del salvataggio.
///
/// Nessun dato entra in archivio senza passare di qui. Su misure di
/// laboratorio un'estrazione automatica accettata in silenzio sarebbe
/// inaccettabile: un punto decimale letto male cambia il significato clinico
/// di un valore, e chi consulta lo storico mesi dopo non ha modo di
/// accorgersene.
///
/// La schermata mostra quindi come è stato ottenuto il testo, quali righe non
/// sono state interpretate, e permette di correggere o escludere ogni voce.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/db/repositories/report_repository.dart';
import '../import/import_service.dart';
import '../parsing/models.dart';
import '../parsing/plausibility.dart';
import '../parsing/text_normalizer.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    super.key,
    required this.patientId,
    required this.extraction,
  });

  final int patientId;
  final ExtractionResult extraction;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late List<ParsedAnalyte> _analytes;
  late Set<int> _included;
  DateTime? _examDate;
  DuplicateReport? _duplicate;
  bool _saving = false;

  /// Distingue la data scelta dall'utente da quella letta dal referto: la
  /// schermata non deve dichiarare di averla trovata nel documento quando in
  /// realtà l'ha appena digitata chi importa.
  bool _dateManuallySet = false;

  ParsedReport get _report => widget.extraction.report;

  @override
  void initState() {
    super.initState();
    _analytes = [..._report.analytes];
    _included = {for (var i = 0; i < _analytes.length; i++) i};
    _examDate = _report.examDate;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDuplicate());
  }

  Future<void> _checkDuplicate() async {
    final date = _examDate;
    if (date == null) return;
    final found = await ref.read(reportRepositoryProvider).findDuplicate(
      patientId: widget.patientId,
      examDate: date,
      reportNumber: _report.reportNumber,
    );
    if (mounted) {
      setState(() {
        _duplicate = found;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Data del prelievo',
    );
    if (picked != null) {
      setState(() {
        _examDate = picked;
        _duplicate = null;
        _dateManuallySet = true;
      });
      await _checkDuplicate();
    }
  }

  Future<void> _editAnalyte(int index) async {
    final edited = await showDialog<ParsedAnalyte>(
      context: context,
      builder: (_) => _AnalyteEditor(analyte: _analytes[index]),
    );
    if (edited != null) setState(() => _analytes[index] = edited);
  }

  /// Applica la correzione proposta dal controllo di plausibilità.
  void _applySuggestion(int index, double suggested) {
    setState(() {
      _analytes[index] = _analytes[index].copyWith(value: suggested);
    });
  }

  /// Voci sospette fra quelle effettivamente selezionate per il salvataggio.
  List<({ParsedAnalyte analyte, ImplausibleValue warning})> get _suspicious {
    final found = <({ParsedAnalyte analyte, ImplausibleValue warning})>[];
    for (var i = 0; i < _analytes.length; i++) {
      if (!_included.contains(i)) continue;
      final w = Plausibility.checkAnalyte(_analytes[i]);
      if (w != null) found.add((analyte: _analytes[i], warning: w));
    }
    return found;
  }

  Future<void> _save() async {
    final date = _examDate;
    if (date == null) return;

    // Il salvataggio non viene impedito: esistono valori legittimamente
    // estremi, e un blocco costringerebbe a falsificare il dato per aggirarlo.
    // Ma passarci sopra dev'essere una scelta consapevole, non un tocco
    // distratto: chi rilegge lo storico fra sei mesi non avrà più modo di
    // accorgersi dell'errore.
    final suspicious = _suspicious;
    if (suspicious.isNotEmpty) {
      final proceed = await _confirmSuspicious(suspicious);
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    final selected = [
      for (var i = 0; i < _analytes.length; i++)
        if (_included.contains(i)) _analytes[i],
    ];

    try {
      await ref.read(reportRepositoryProvider).save(
        patientId: widget.patientId,
        examDate: date,
        analytes: selected,
        sourceKind: widget.extraction.document.kind,
        sourceName: widget.extraction.document.name,
        laboratory: _report.laboratory,
        reportNumber: _report.reportNumber,
        originalDocument: widget.extraction.document.bytes,
        rawText: _report.rawText,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Referto salvato: ${selected.length} valori')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salvataggio non riuscito: $e')),
        );
      }
    }
  }

  Future<bool?> _confirmSuspicious(
    List<({ParsedAnalyte analyte, ImplausibleValue warning})> suspicious,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          icon: Icon(Icons.rule_outlined, color: theme.colorScheme.tertiary),
          title: Text(
            suspicious.length == 1
                ? 'Un valore sembra sbagliato'
                : '${suspicious.length} valori sembrano sbagliati',
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in suspicious) ...[
                  Text(
                    '${s.analyte.displayName}: '
                    '${s.analyte.value} ${s.analyte.unit}'.trim(),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(s.warning.message, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Salvandoli così resteranno nello storico, e più avanti non '
                  'sarà possibile riconoscerli come errati.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Torna a correggerli'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Salva così'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSave = _examDate != null && _included.isNotEmpty && !_saving;
    final suspiciousCount = _suspicious.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controlla i valori'),
        actions: [
          TextButton(
            onPressed: _included.length == _analytes.length
                ? () => setState(_included.clear)
                : () => setState(() {
                      _included = {
                        for (var i = 0; i < _analytes.length; i++) i,
                      };
                    }),
            child: Text(
              _included.length == _analytes.length
                  ? 'Deseleziona tutto'
                  : 'Seleziona tutto',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: canSave ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _examDate == null
                  ? 'Indica la data del prelievo'
                  : 'Salva ${_included.length} valori',
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _SourceBanner(extraction: widget.extraction),
          _DateSection(
            date: _examDate,
            label: _report.examDateLabel,
            manuallySet: _dateManuallySet,
            candidates: _report.dateCandidates,
            onPick: _pickDate,
            onChoose: (d) async {
              setState(() {
                _examDate = d;
                _dateManuallySet = true;
              });
              await _checkDuplicate();
            },
          ),
          if (_duplicate != null)
            _Warning(
              icon: Icons.copy_all_outlined,
              tone: _Tone.warning,
              title: 'Referto forse già presente',
              body: 'Per questo paziente risulta già archiviato un prelievo '
                  'del ${DateFormat('d MMMM y', 'it_IT').format(_duplicate!.report.examDate)} '
                  'con ${_duplicate!.measurementCount} valori. '
                  'Salvando di nuovo, i punti sul grafico verranno raddoppiati.',
            ),
          if (_report.patient.fiscalCode != null)
            _PatientMatch(
              patientId: widget.patientId,
              fiscalCode: _report.patient.fiscalCode!,
            ),
          if (suspiciousCount > 0)
            _Warning(
              icon: Icons.rule_outlined,
              tone: _Tone.warning,
              title: suspiciousCount == 1
                  ? 'Un valore sembra sbagliato'
                  : '$suspiciousCount valori sembrano sbagliati',
              body: 'Sono segnalati qui sotto. Non è un giudizio clinico: '
                  'l\'app confronta il valore con l\'intervallo stampato sullo '
                  'stesso referto e riconosce solo gli errori di lettura, come '
                  'una virgola persa. Un esame realmente alterato non viene '
                  'segnalato.',
            ),
          for (final w in _report.warnings)
            _Warning(
              icon: Icons.info_outline,
              tone: _Tone.info,
              title: 'Nota di lettura',
              body: w,
            ),
          if (_analytes.isEmpty)
            const _Warning(
              icon: Icons.error_outline,
              tone: _Tone.error,
              title: 'Nessun valore riconosciuto',
              body: 'Il documento non contiene esami interpretabili. '
                  'Verifica che sia un referto di laboratorio, oppure '
                  'riprova con una foto più nitida e ben illuminata.',
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Valori estratti',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tocca una voce per correggerla. Togli la spunta per non '
              'archiviarla.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _analytes.length; i++)
            _AnalyteTile(
              analyte: _analytes[i],
              included: _included.contains(i),
              warning: Plausibility.checkAnalyte(_analytes[i]),
              onApplySuggestion: (v) => _applySuggestion(i, v),
              onToggle: (v) => setState(() {
                if (v) {
                  _included.add(i);
                } else {
                  _included.remove(i);
                }
              }),
              onEdit: () => _editAnalyte(i),
            ),
        ],
      ),
    );
  }
}

class _SourceBanner extends StatelessWidget {
  const _SourceBanner({required this.extraction});

  final ExtractionResult extraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            extraction.usedOcr ? Icons.center_focus_weak : Icons.text_snippet_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(extraction.document.name,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  extraction.usedOcr
                      ? '${extraction.method} — il riconoscimento da immagine '
                            'può sbagliare: controlla con attenzione'
                      : extraction.method,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.date,
    required this.label,
    required this.manuallySet,
    required this.candidates,
    required this.onPick,
    required this.onChoose,
  });

  final DateTime? date;
  final String? label;
  final bool manuallySet;
  final List<DateCandidate> candidates;
  final VoidCallback onPick;
  final ValueChanged<DateTime> onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = date == null;

    // Date distinte fra loro: se tutte le candidate coincidono non c'è nulla
    // da scegliere e proporre un elenco confonderebbe soltanto.
    final distinct = <DateTime, DateCandidate>{};
    for (final c in candidates) {
      distinct.putIfAbsent(DateTime(c.date.year, c.date.month, c.date.day), () => c);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: missing ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
          width: missing ? 1.6 : 1,
        ),
        color: missing ? theme.colorScheme.errorContainer.withValues(alpha: 0.25) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 20,
                  color: missing ? theme.colorScheme.error : null),
              const SizedBox(width: 10),
              Text('Data del prelievo', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          if (missing)
            Text(
              'Non è stata trovata nel documento: indicala tu, altrimenti i '
              'valori non possono essere collocati nello storico.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else
            Text(
              manuallySet
                  ? 'Inserita manualmente.'
                  : 'Letta dal documento${label != null ? ' ($label)' : ''}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.edit_calendar_outlined),
            label: Text(
              date == null
                  ? 'Scegli la data'
                  : DateFormat('d MMMM y', 'it_IT').format(date!),
            ),
          ),
          if (distinct.length > 1) ...[
            const SizedBox(height: 12),
            Text(
              'Altre date presenti nel documento:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in distinct.values)
                  ActionChip(
                    label: Text(
                      '${DateFormat('d/M/y').format(c.date)} · ${c.label}',
                    ),
                    onPressed: () => onChoose(c.date),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PatientMatch extends ConsumerWidget {
  const _PatientMatch({required this.patientId, required this.fiscalCode});

  final int patientId;
  final String fiscalCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(patientsProvider);

    return patients.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (list) {
        final current = list.where((p) => p.id == patientId).firstOrNull;
        if (current == null) return const SizedBox.shrink();

        final owner = list
            .where((p) => p.fiscalCode == fiscalCode)
            .firstOrNull;

        // Il referto appartiene a un altro paziente registrato: è l'errore
        // più dannoso possibile qui, perché mescolerebbe gli storici clinici
        // di due persone diverse.
        if (owner != null && owner.id != patientId) {
          return _Warning(
            icon: Icons.person_off_outlined,
            tone: _Tone.error,
            title: 'Il referto risulta di un altro paziente',
            body: 'Il codice fiscale sul documento ($fiscalCode) corrisponde '
                'a ${owner.fullName}, non a ${current.fullName}. '
                'Verifica prima di salvare.',
          );
        }

        if (current.fiscalCode != null && current.fiscalCode != fiscalCode) {
          return _Warning(
            icon: Icons.help_outline,
            tone: _Tone.warning,
            title: 'Codice fiscale diverso',
            body: 'Sul documento risulta $fiscalCode, mentre '
                '${current.fullName} ha ${current.fiscalCode}.',
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

enum _Tone { info, warning, error }

class _Warning extends StatelessWidget {
  const _Warning({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final _Tone tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final color = switch (tone) {
      _Tone.info => scheme.onSurfaceVariant,
      _Tone.warning => scheme.tertiary,
      _Tone.error => scheme.error,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.07),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyteTile extends StatelessWidget {
  const _AnalyteTile({
    required this.analyte,
    required this.included,
    required this.onToggle,
    required this.onEdit,
    this.warning,
    this.onApplySuggestion,
  });

  final ParsedAnalyte analyte;
  final bool included;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  /// Esito del controllo di plausibilità, `null` se non c'è nulla da dire.
  final ImplausibleValue? warning;

  final ValueChanged<double>? onApplySuggestion;

  @override
  Widget build(BuildContext context) {
    final w = warning;
    if (w == null) return _tile(context);

    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    final suggested = w.suggested;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tile(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.rule_outlined, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(w.message, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
          if (suggested != null && onApplySuggestion != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => onApplySuggestion!(suggested),
                  icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: Text('Correggi in ${_fmt(suggested)}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.paletteOf(context);
    final reference = analyte.reference.label;

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: included,
        onChanged: (v) => onToggle(v ?? false),
      ),
      title: Text(analyte.displayName),
      subtitle: reference.isEmpty
          ? null
          : Text(
              'rif. $reference',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            analyte.value != null
                ? _fmt(analyte.value!)
                : (analyte.rawValue ?? '—'),
            style: theme.textTheme.titleSmall?.copyWith(
              color: warning != null
                  ? theme.colorScheme.tertiary
                  : (analyte.flag == ValueFlag.normal
                      ? null
                      : palette.of(analyte.flag)),
              fontWeight: warning != null ? FontWeight.w700 : null,
            ),
          ),
          if (analyte.unit.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              analyte.unit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(width: 4),
          const Icon(Icons.edit_outlined, size: 16),
        ],
      ),
      onTap: onEdit,
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() && v.abs() < 1e9 ? v.toStringAsFixed(0) : '$v';
}

/// Correzione di una singola voce.
class _AnalyteEditor extends StatefulWidget {
  const _AnalyteEditor({required this.analyte});

  final ParsedAnalyte analyte;

  @override
  State<_AnalyteEditor> createState() => _AnalyteEditorState();
}

class _AnalyteEditorState extends State<_AnalyteEditor> {
  late final TextEditingController _name;
  late final TextEditingController _value;
  late final TextEditingController _unit;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.analyte.displayName);
    _value = TextEditingController(
      text: widget.analyte.value != null
          ? '${widget.analyte.value}'
          : (widget.analyte.rawValue ?? ''),
    );
    _unit = TextEditingController(text: widget.analyte.unit);
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Correggi il valore'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Esame'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Valore'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unit,
                  decoration: const InputDecoration(labelText: 'Unità'),
                ),
              ),
            ],
          ),
          if (widget.analyte.reference.raw.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riferimento sul referto: ${widget.analyte.reference.raw}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = TextNormalizer.parseNumber(_value.text);
            Navigator.of(context).pop(
              widget.analyte.copyWith(
                displayName: _name.text.trim(),
                value: parsed,
                unit: TextNormalizer.normalizeUnit(_unit.text),
              ),
            );
          },
          child: const Text('Applica'),
        ),
      ],
    );
  }
}
