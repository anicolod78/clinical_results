/// Scelta dell'analita da rappresentare nel grafico.
///
/// Un referto completo produce decine di serie: sceglierle da una striscia
/// che scorre in orizzontale costringe a passarle tutte in rassegna per
/// trovarne una. Qui si aprono in un elenco raggruppato per pannello, con un
/// campo di ricerca e il valore più recente accanto a ogni voce, così la
/// scelta si fa leggendo invece che scorrendo.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/db/repositories/series_repository.dart';
import '../parsing/models.dart';

/// Mostra l'elenco e restituisce la serie scelta, `null` se si annulla.
Future<AnalyteSeries?> showSeriesPicker(
  BuildContext context, {
  required List<AnalyteSeries> series,
  required String? selectedKey,
}) {
  return showModalBottomSheet<AnalyteSeries>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SeriesPicker(series: series, selectedKey: selectedKey),
  );
}

class _SeriesPicker extends StatefulWidget {
  const _SeriesPicker({required this.series, required this.selectedKey});

  final List<AnalyteSeries> series;
  final String? selectedKey;

  @override
  State<_SeriesPicker> createState() => _SeriesPickerState();
}

class _SeriesPickerState extends State<_SeriesPicker> {
  final _search = TextEditingController();
  late final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Filtra su nome e unità, ignorando accenti e maiuscole.
  ///
  /// L'unità entra nella ricerca perché è ciò che distingue le due misure
  /// dello stesso analita: scrivendo "%" si isolano subito le percentuali.
  List<AnalyteSeries> get _filtered {
    final query = _normalize(_search.text);
    if (query.isEmpty) return widget.series;
    return widget.series
        .where((s) =>
            _normalize(s.displayName).contains(query) ||
            _normalize(s.unit).contains(query) ||
            _normalize(s.group).contains(query))
        .toList();
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àáâä]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôö]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.paletteOf(context);
    final results = _filtered;

    // Mantiene l'ordine dei gruppi già stabilito dal repository.
    final grouped = <String, List<AnalyteSeries>>{};
    for (final s in results) {
      grouped.putIfAbsent(s.group, () => []).add(s);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scegli un esame',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${widget.series.length} disponibili',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                focusNode: _focus,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cerca per nome o unità',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Cancella',
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (results.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Nessun esame corrisponde a "${_search.text}".',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.8,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      for (final s in entry.value)
                        _SeriesTile(
                          series: s,
                          selected: s.canonicalKey == widget.selectedKey,
                          palette: palette,
                          onTap: () => Navigator.of(context).pop(s),
                        ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SeriesTile extends StatelessWidget {
  const _SeriesTile({
    required this.series,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final AnalyteSeries series;
  final bool selected;
  final FlagPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = series.latest;

    return ListTile(
      selected: selected,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      title: Text(series.displayName),
      subtitle: Text(
        [
          if (series.unit.isNotEmpty) series.unit,
          '${series.points.length} ${series.points.length == 1 ? 'misura' : 'misure'}',
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: latest == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  latest.display,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: latest.flag == ValueFlag.normal
                        ? null
                        : palette.of(latest.flag),
                  ),
                ),
                if (flagIcon(latest.flag) != null) ...[
                  const SizedBox(width: 2),
                  Icon(flagIcon(latest.flag),
                      size: 14, color: palette.of(latest.flag)),
                ],
              ],
            ),
      onTap: onTap,
    );
  }
}
