/// Andamento di un analita nel tempo.
///
/// Oltre ai valori il grafico mostra la fascia dell'intervallo di riferimento:
/// senza di essa una linea di numeri non dice se la situazione stia migliorando
/// o peggiorando, che è l'unica cosa che interessa davvero guardando lo storico.
///
/// L'asse orizzontale è proporzionale al tempo trascorso, non alla sequenza dei
/// prelievi: distribuire a distanze uguali esami fatti a settimane o ad anni di
/// distanza darebbe un'idea sbagliata della rapidità dei cambiamenti.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/db/repositories/series_repository.dart';
import '../parsing/models.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.series});

  final AnalyteSeries series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.paletteOf(context);
    final points = series.points.where((p) => p.value != null).toList();

    if (points.isEmpty) {
      return _Message(text: 'Nessun valore numerico da rappresentare.');
    }
    if (points.length < 2) {
      return _Message(
        text: 'Serve almeno un secondo prelievo per vedere un andamento.\n'
            'Valore attuale: ${points.single.display} ${series.unit}',
      );
    }

    final origin = points.first.date;
    double x(DateTime d) => d.difference(origin).inDays.toDouble();

    final spots = [
      for (final p in points) FlSpot(x(p.date), p.value!),
    ];

    // La fascia di riferimento più recente: le soglie possono cambiare fra
    // laboratori, e mostrare quella attuale evita di confondere le idee.
    final reference = points.lastWhere(
      (p) => p.refLow != null || p.refHigh != null,
      orElse: () => points.last,
    );

    final values = points.map((p) => p.value!).toList();
    final bounds = _computeBounds(values, reference);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 20, 24),
      child: LineChart(
        LineChartData(
          minY: bounds.min,
          maxY: bounds.max,
          minX: spots.first.x,
          maxX: spots.last.x,
          clipData: const FlClipData.all(),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              if (reference.refLow != null || reference.refHigh != null)
                HorizontalRangeAnnotation(
                  y1: reference.refLow ?? bounds.min,
                  y2: reference.refHigh ?? bounds.max,
                  // La fascia di un obiettivo terapeutico non è la fascia di
                  // normalità di un laboratorio: dipingerle uguali farebbe
                  // leggere come "nella norma" ciò che è "entro l'obiettivo".
                  color: reference.isDesirable
                      ? palette.target.withValues(alpha: 0.10)
                      : palette.normal.withValues(alpha: 0.10),
                ),
            ],
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 0.6,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  _short(value),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _labelInterval(spots.last.x),
                getTitlesWidget: (value, meta) {
                  final date = origin.add(Duration(days: value.round()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MM/yy').format(date),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => [
                for (final t in touched)
                  LineTooltipItem(
                    '${_short(t.y)} ${series.unit}\n'
                    '${DateFormat('d MMM y', 'it_IT').format(origin.add(Duration(days: t.x.round())))}',
                    theme.textTheme.bodySmall ?? const TextStyle(),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              barWidth: 2.4,
              color: theme.colorScheme.primary,
              dotData: FlDotData(
                getDotPainter: (spot, _, _, index) {
                  final flag = points[index].flag;
                  return FlDotCirclePainter(
                    radius: 4.5,
                    color: flag == ValueFlag.normal ||
                            flag == ValueFlag.unknown
                        ? theme.colorScheme.primary
                        : palette.of(flag),
                    strokeWidth: 1.6,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Estende i limiti verticali in modo che la fascia di riferimento sia
  /// sempre visibile, anche quando tutti i valori stanno da una parte sola.
  static ({double min, double max}) _computeBounds(
    List<double> values,
    MeasurementPoint reference,
  ) {
    var min = values.reduce((a, b) => a < b ? a : b);
    var max = values.reduce((a, b) => a > b ? a : b);

    if (reference.refLow != null) min = min < reference.refLow! ? min : reference.refLow!;
    if (reference.refHigh != null) max = max > reference.refHigh! ? max : reference.refHigh!;

    final span = (max - min).abs();
    final padding = span == 0 ? (max.abs() * 0.1 + 1) : span * 0.15;
    return (min: min - padding, max: max + padding);
  }

  static double _labelInterval(double totalDays) {
    if (totalDays <= 0) return 1;
    // Circa quattro etichette sull'asse, arrotondate a un numero intero
    // di giorni per non ripetere lo stesso mese due volte.
    final raw = totalDays / 4;
    return raw < 1 ? 1 : raw.roundToDouble();
  }

  static String _short(double v) {
    if (v == v.roundToDouble() && v.abs() < 10000) return v.toStringAsFixed(0);
    if (v.abs() < 10) return v.toStringAsFixed(2);
    return v.toStringAsFixed(1);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
