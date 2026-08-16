/// Scheda del paziente: tabella dei valori, andamenti e referti archiviati.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/db/repositories/series_repository.dart';
import '../../core/db/tables.dart' show SourceKind;
import '../charts/series_picker.dart';
import '../charts/trend_chart.dart';
import '../import/import_flow.dart';
import '../parsing/models.dart';
import '../results/merge_series_screen.dart';
import '../results/results_table_view.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({super.key, required this.patientId});

  final int patientId;

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  String? _selectedKey;

  /// Indice della scheda con l'elenco dei referti.
  ///
  /// È l'unica in cui compare il pulsante di importazione: sulle altre due
  /// fluttua sopra i dati e ne copre una parte, e né la tabella né il grafico
  /// hanno modo di spostarsi. Qui invece l'elenco scorre e il pulsante è
  /// anche contestualmente al posto giusto.
  static const _reportsTab = 2;

  @override
  void initState() {
    super.initState();
    // Il pulsante di importazione compare solo su alcune schede: serve
    // ridisegnare quando si cambia scheda.
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showSeries(AnalyteSeries series) {
    setState(() => _selectedKey = series.canonicalKey);
    _tabs.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final table = ref.watch(resultsTableProvider(widget.patientId));
    final patients = ref.watch(patientsProvider);
    final name = patients.maybeWhen(
      data: (list) => list
          .where((p) => p.id == widget.patientId)
          .map((p) => p.fullName)
          .firstOrNull,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(name ?? 'Paziente'),
        actions: [
          IconButton(
            tooltip: 'Unisci esami',
            icon: const Icon(Icons.merge_type),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MergeSeriesScreen(patientId: widget.patientId),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Tabella', icon: Icon(Icons.table_chart_outlined)),
            Tab(text: 'Andamenti', icon: Icon(Icons.show_chart)),
            Tab(text: 'Referti', icon: Icon(Icons.description_outlined)),
          ],
        ),
      ),
      floatingActionButton: _tabs.index != _reportsTab
          ? null
          : FloatingActionButton.extended(
              onPressed: () => startImport(context, ref, widget.patientId),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Importa referto'),
            ),
      body: table.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e', textAlign: TextAlign.center),
        )),
        // Il contenuto delle schede si fermava sotto la barra di navigazione
        // di sistema, che copriva le etichette delle date in fondo al
        // grafico. Solo il bordo inferiore va rispettato: in alto c'è già la
        // barra delle schede.
        data: (data) => SafeArea(
          top: false,
          child: TabBarView(
            controller: _tabs,
            children: [
              data.isEmpty
                  ? const _NoResults()
                  : ResultsTableView(table: data, onSelectSeries: _showSeries),
              _TrendsTab(
                table: data,
                selectedKey: _selectedKey,
                onSelect: (k) => setState(() => _selectedKey = k),
              ),
              _ReportsTab(patientId: widget.patientId),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendsTab extends StatelessWidget {
  const _TrendsTab({
    required this.table,
    required this.selectedKey,
    required this.onSelect,
  });

  final ResultsTable table;
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (table.isEmpty) return const _NoResults();

    final theme = Theme.of(context);
    final comparable =
        table.series.where((s) => s.isNumeric).toList(growable: false);
    if (comparable.isEmpty) return const _NoResults();

    final selected = comparable.firstWhere(
      (s) => s.canonicalKey == selectedKey,
      orElse: () => comparable.first,
    );

    return Column(
      children: [
        // Selettore a elenco invece che a scorrimento orizzontale: con
        // decine di analiti una striscia di pastiglie obbliga a scorrere
        // alla cieca per trovare quello che serve.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final chosen = await showSeriesPicker(
                context,
                series: comparable,
                selectedKey: selected.canonicalKey,
              );
              if (chosen != null) onSelect(chosen.canonicalKey);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: const Icon(Icons.monitor_heart_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                helperText: '${comparable.length} esami disponibili',
              ),
              child: Text(
                selected.label,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        _SeriesSummary(series: selected),
        Expanded(child: TrendChart(series: selected)),
      ],
    );
  }
}

class _SeriesSummary extends StatelessWidget {
  const _SeriesSummary({required this.series});

  final AnalyteSeries series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.paletteOf(context);
    final latest = series.latest;
    if (latest == null) return const SizedBox.shrink();

    final delta = series.lastDelta;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(latest.display, style: theme.textTheme.headlineMedium),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              series.unit,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (delta != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    delta > 0 ? Icons.trending_up : (delta < 0 ? Icons.trending_down : Icons.trending_flat),
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${delta > 0 ? '+' : ''}${_fmt(delta)} dal precedente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          if (latest.referenceLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'rif. ${latest.referenceLabel}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: latest.flag == ValueFlag.normal
                      ? theme.colorScheme.onSurfaceVariant
                      : palette.of(latest.flag),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble() && v.abs() < 10000) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab({required this.patientId});

  final int patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(patientReportsProvider(patientId));

    return reports.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (list.isEmpty) return const _NoResults();
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => _ReportTile(report: list[i]),
        );
      },
    );
  }
}

class _ReportTile extends ConsumerWidget {
  const _ReportTile({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final icon = switch (report.sourceKind) {
      SourceKind.pdf => Icons.picture_as_pdf_outlined,
      SourceKind.image => Icons.image_outlined,
      SourceKind.manual => Icons.edit_note_outlined,
    };

    return ListTile(
      leading: Icon(icon),
      title: Text(
        DateFormat('d MMMM y', 'it_IT').format(report.examDate),
      ),
      subtitle: Text(
        [
          if (report.laboratory != null) report.laboratory!,
          if (report.reportNumber != null) 'n. ${report.reportNumber}',
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Elimina referto',
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Eliminare il referto?'),
              content: Text(
                'Verranno rimossi anche i valori del prelievo del '
                '${DateFormat('d MMMM y', 'it_IT').format(report.examDate)}.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Elimina'),
                ),
              ],
            ),
          );
          if (ok == true) {
            await ref.read(reportRepositoryProvider).delete(report.id);
          }
        },
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined,
                size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Nessun referto', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Importa un referto in PDF, oppure fotografalo: '
              'i valori verranno estratti e messi a confronto nel tempo.',
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
