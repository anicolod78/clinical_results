/// Unione manuale di serie che il riconoscimento ha tenuto separate.
///
/// Capita quando lo stesso esame viene letto in due modi: un nome storpiato
/// dall'OCR, un'unità irriconoscibile. Le riparazioni automatiche coprono i
/// casi ricorrenti — unità troncate, percentuale desumibile dal nome — ma non
/// possono coprirli tutti senza rischiare di unire esami davvero distinti.
///
/// Qui la decisione la prende chi sa cosa c'era sul referto.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/db/repositories/series_repository.dart';
import 'merge_suggestions.dart';

class MergeSeriesScreen extends ConsumerWidget {
  const MergeSeriesScreen({super.key, required this.patientId});

  final int patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(resultsTableProvider(patientId));
    final aliases = ref.watch(aliasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Unisci esami')),
      body: table.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) => SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const _Intro(),
              _ActiveMerges(
                aliases: aliases.valueOrNull ?? const [],
                patientId: patientId,
              ),
              _Suggestions(table: data, patientId: patientId),
              _AllSeries(table: data, patientId: patientId),
            ],
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'Se lo stesso esame compare due volte perché è stato letto in modi '
        'diversi, puoi indicarlo qui. I valori restano come sono stati '
        'acquisiti: viene registrata solo la corrispondenza, e si può '
        'annullare in qualsiasi momento.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ActiveMerges extends ConsumerWidget {
  const _ActiveMerges({required this.aliases, required this.patientId});

  final List<AnalyteAlias> aliases;
  final int patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (aliases.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Unioni attive'),
        for (final alias in aliases)
          ListTile(
            leading: const Icon(Icons.merge_type),
            title: Text('${alias.fromLabel}  →  ${alias.toLabel}'),
            subtitle: Text(
              'dal ${DateFormat('d MMM y', 'it_IT').format(alias.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: TextButton(
              onPressed: () => ref
                  .read(seriesRepositoryProvider)
                  .undoMerge(alias.fromKey),
              child: const Text('Annulla'),
            ),
          ),
        const Divider(),
      ],
    );
  }
}

/// Coppie che sembrano lo stesso esame letto in due modi.
///
/// Il criterio è in [findMergeCandidates], tenuto a parte perché è la parte
/// che può fare danno: proporre di unire due esami distinti porterebbe a
/// mescolare valori senza che nulla lo segnali in seguito.
class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.table, required this.patientId});

  final ResultsTable table;
  final int patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairs = findMergeCandidates(table.series);
    if (pairs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Possibili letture errate'),
        for (final pair in pairs)
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text('${pair.misread.label}  →  ${pair.known.label}'),
            subtitle: Text(
              '"${pair.misread.displayName}" non risulta un esame noto e '
              'somiglia a "${pair.known.displayName}": '
              '${pair.misread.points.length} e ${pair.known.points.length} '
              'misure.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: FilledButton.tonal(
              onPressed: () => ref.read(seriesRepositoryProvider).mergeSeries(
                source: pair.misread,
                target: pair.known,
              ),
              child: const Text('Unisci'),
            ),
          ),
        const Divider(),
      ],
    );
  }
}

class _AllSeries extends ConsumerWidget {
  const _AllSeries({required this.table, required this.patientId});

  final ResultsTable table;
  final int patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Tutti gli esami'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Tocca un esame per unirlo a un altro.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final s in table.series)
          ListTile(
            dense: true,
            title: Text(s.label),
            subtitle: Text(
              '${s.points.length} '
              '${s.points.length == 1 ? 'misura' : 'misure'}',
            ),
            trailing: const Icon(Icons.merge_type, size: 18),
            onTap: () async {
              final other = await _pickOther(context, table.series, s);
              if (other == null || !context.mounted) return;
              final keep = await _askWhichToKeep(context, s, other);
              if (keep == null) return;
              final source = keep == s ? other : s;
              await ref
                  .read(seriesRepositoryProvider)
                  .mergeSeries(source: source, target: keep);
            },
          ),
      ],
    );
  }

  static Future<AnalyteSeries?> _pickOther(
    BuildContext context,
    List<AnalyteSeries> all,
    AnalyteSeries current,
  ) {
    final others = all.where((s) => s.canonicalKey != current.canonicalKey);
    return showModalBottomSheet<AnalyteSeries>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ListView(
        children: [
          ListTile(
            title: Text(
              'Unire "${current.label}" a…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          for (final s in others)
            ListTile(
              title: Text(s.label),
              subtitle: Text('${s.points.length} misure'),
              onTap: () => Navigator.of(context).pop(s),
            ),
        ],
      ),
    );
  }
}

/// Chiede quale delle due denominazioni conservare.
///
/// La scelta conta: la serie unita prende nome e unità di quella mantenuta, e
/// il valore letto male sparisce dalla vista. Non si può decidere in
/// automatico quale sia la lettura corretta.
Future<AnalyteSeries?> _askWhichToKeep(
  BuildContext context,
  AnalyteSeries a,
  AnalyteSeries b,
) {
  return showDialog<AnalyteSeries>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Quale denominazione tenere?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avviso quando entrambi risultano esami noti e distinti: è il caso
          // di HDL e LDL, che si somigliano nel nome ma non nel significato.
          if (bothAreKnownAnalytes(a, b))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 20, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Risultano due esami distinti e riconosciuti. Unirli '
                      'mescolerebbe misure di significato diverso: procedi '
                      'solo se sai che si tratta della stessa voce letta male.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Le misure di entrambe confluiranno in un unico andamento, con la '
            'denominazione che scegli.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final s in [a, b])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.label),
              subtitle: Text('${s.points.length} misure'),
              onTap: () => Navigator.of(context).pop(s),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.8,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
