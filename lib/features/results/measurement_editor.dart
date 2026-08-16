/// Correzione di una misura già archiviata.
///
/// Un errore di lettura sfuggito alla revisione non deve costringere a
/// reimportare il referto: rifare quel percorso significa rischiare di
/// duplicare il prelievo, e chi si accorge dello sbaglio mesi dopo non ha più
/// il documento sottomano. Qui si corregge la singola cifra, lasciando intatti
/// il collegamento al referto d'origine e l'intervallo di riferimento con cui
/// era stata archiviata.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/db/repositories/series_repository.dart';
import '../parsing/plausibility.dart';
import '../parsing/text_normalizer.dart';

Future<void> showMeasurementEditor({
  required BuildContext context,
  required WidgetRef ref,
  required AnalyteSeries series,
  required MeasurementPoint point,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _MeasurementEditor(series: series, point: point, ref: ref),
  );
}

class _MeasurementEditor extends StatefulWidget {
  const _MeasurementEditor({
    required this.series,
    required this.point,
    required this.ref,
  });

  final AnalyteSeries series;
  final MeasurementPoint point;
  final WidgetRef ref;

  @override
  State<_MeasurementEditor> createState() => _MeasurementEditorState();
}

class _MeasurementEditorState extends State<_MeasurementEditor> {
  late final TextEditingController _value;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(
      text: widget.point.value != null ? '${widget.point.value}' : '',
    );
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  ImplausibleValue? get _suspect => Plausibility.check(
        rawName: widget.series.displayName,
        value: widget.point.value,
        unit: widget.series.unit,
        refLow: widget.point.refLow,
        refHigh: widget.point.refHigh,
        isDesirable: widget.point.isDesirable,
      );

  Future<void> _save() async {
    final parsed = TextNormalizer.parseNumber(_value.text);
    if (parsed == null) return;

    setState(() => _working = true);
    await widget.ref.read(seriesRepositoryProvider).updateMeasurementValue(
          measurementId: widget.point.measurementId,
          value: parsed,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    // Cancellare un dato clinico non si annulla: la conferma è d'obbligo.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare questa misura?'),
        content: Text(
          '${widget.series.displayName} del '
          '${DateFormat('d MMMM y', 'it_IT').format(widget.point.date)} '
          'verrà tolta dallo storico. Il referto da cui proviene resta '
          'archiviato, con tutti gli altri suoi valori.',
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

    setState(() => _working = true);
    await widget.ref
        .read(seriesRepositoryProvider)
        .deleteMeasurement(widget.point.measurementId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.point;
    final suspect = _suspect;
    final reference = p.referenceLabel;

    return AlertDialog(
      title: Text(widget.series.displayName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prelievo del ${DateFormat('d MMMM y', 'it_IT').format(p.date)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (reference.isNotEmpty)
              Text(
                'Riferimento sul referto: $reference',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            if (suspect != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
                  ),
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.07),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.rule_outlined,
                        size: 18, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        suspect.message,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (suspect.suggested != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: _working
                        ? null
                        : () => setState(() {
                              _value.text = '${suspect.suggested}';
                            }),
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                    label: Text('Usa ${suspect.suggested}'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _value,
              autofocus: true,
              enabled: !_working,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
              ],
              decoration: InputDecoration(
                labelText: 'Valore',
                suffixText: widget.series.unit,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : _delete,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          child: const Text('Elimina'),
        ),
        TextButton(
          onPressed: _working ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _working ? null : _save,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
