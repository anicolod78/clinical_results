/// Vista tabellare dei risultati: analiti in riga, prelievi in colonna.
///
/// La colonna dei nomi resta ferma mentre le date scorrono in orizzontale:
/// con più prelievi a confronto, perdere di vista il nome dell'esame renderebbe
/// la tabella illeggibile proprio quando serve di più.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/db/repositories/series_repository.dart';
import '../parsing/models.dart';
import 'stored_value_check.dart';

class ResultsTableView extends StatefulWidget {
  const ResultsTableView({
    super.key,
    required this.table,
    this.onSelectSeries,
    this.onCorrectPoint,
  });

  final ResultsTable table;
  final ValueChanged<AnalyteSeries>? onSelectSeries;

  /// Correzione di una singola misura già archiviata.
  final void Function(AnalyteSeries series, MeasurementPoint point)?
      onCorrectPoint;

  @override
  State<ResultsTableView> createState() => _ResultsTableViewState();
}

class _ResultsTableViewState extends State<ResultsTableView> {
  static const _nameWidth = 172.0;
  static const _cellWidth = 96.0;
  static const _rowHeight = 46.0;

  /// Due viste scorrevoli tenute allineate: l'intestazione con le date e il
  /// corpo della tabella. Sincronizzarle è ciò che rende la colonna dei nomi
  /// stabile senza rinunciare allo scorrimento orizzontale.
  final _headerScroll = ScrollController();
  final _bodyScroll = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _headerScroll.addListener(() => _sync(_headerScroll, _bodyScroll));
    _bodyScroll.addListener(() => _sync(_bodyScroll, _headerScroll));
  }

  void _sync(ScrollController from, ScrollController to) {
    if (_syncing || !to.hasClients) return;
    if (to.offset == from.offset) return;
    _syncing = true;
    to.jumpTo(from.offset);
    _syncing = false;
  }

  @override
  void dispose() {
    _headerScroll.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final table = widget.table;
    final dates = table.dates;
    final groups = table.byGroup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intestazione con le date dei prelievi.
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: _nameWidth, height: 52),
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerScroll,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final date in dates)
                        SizedBox(
                          width: _cellWidth,
                          height: 52,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('d MMM', 'it_IT').format(date),
                                  style: theme.textTheme.labelMedium,
                                ),
                                Text(
                                  DateFormat('y').format(date),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            // Poco spazio in coda: il pulsante di importazione non compare
            // più su questa scheda, serve solo a non far terminare l'ultima
            // riga a filo del bordo.
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonna fissa dei nomi.
                SizedBox(
                  width: _nameWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in groups.entries) ...[
                        _GroupHeader(title: entry.key, width: _nameWidth),
                        for (final s in entry.value)
                          _NameCell(
                            series: s,
                            height: _rowHeight,
                            onTap: widget.onSelectSeries == null
                                ? null
                                : () => widget.onSelectSeries!(s),
                          ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _bodyScroll,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in groups.entries) ...[
                          SizedBox(
                            height: 32,
                            width: _cellWidth * dates.length,
                          ),
                          for (final s in entry.value)
                            Row(
                              children: [
                                for (final date in dates)
                                  _ValueCell(
                                    series: s,
                                    point: table.at(s, date),
                                    width: _cellWidth,
                                    height: _rowHeight,
                                    onCorrect: widget.onCorrectPoint,
                                  ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.width});

  final String title;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      color: theme.colorScheme.surfaceContainer,
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.6,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.series, required this.height, this.onTap});

  final AnalyteSeries series;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            right: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              series.displayName,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (series.unit.isNotEmpty)
              Text(
                series.unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.series,
    required this.point,
    required this.width,
    required this.height,
    this.onCorrect,
  });

  final AnalyteSeries series;
  final MeasurementPoint? point;
  final double width;
  final double height;
  final void Function(AnalyteSeries series, MeasurementPoint point)? onCorrect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.paletteOf(context);
    final p = point;

    final cell = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: p == null
          ? Text(
              '—',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          : _content(context, p, theme, palette),
    );

    if (p == null || onCorrect == null) return cell;
    return InkWell(onTap: () => onCorrect!(series, p), child: cell);
  }

  Widget _content(
    BuildContext context,
    MeasurementPoint p,
    ThemeData theme,
    FlagPalette palette,
  ) {
    // Lo stesso controllo della revisione, applicato a ciò che è già in
    // archivio: un errore sfuggito allora resta visibile finché non viene
    // corretto, invece di sedimentare come se fosse un dato buono.
    final suspect = checkStoredPoint(series, p);

    if (suspect != null) {
      return Semantics(
        label: '${p.display}, valore sospetto',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              p.display,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.rule_outlined,
                size: 13, color: theme.colorScheme.tertiary),
          ],
        ),
      );
    }

    return Semantics(
      label: '${p.display} ${flagLabel(p.flag)}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            p.display,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: p.flag == ValueFlag.normal ? null : palette.of(p.flag),
              fontWeight: p.flag == ValueFlag.high || p.flag == ValueFlag.low
                  ? FontWeight.w700
                  : null,
            ),
          ),
          if (flagIcon(p.flag) != null) ...[
            const SizedBox(width: 2),
            Icon(flagIcon(p.flag), size: 13, color: palette.of(p.flag)),
          ],
        ],
      ),
    );
  }
}
