/// Serie storiche degli esami, per la tabella e i grafici.
///
/// Tabella e grafico leggono gli stessi dati: la tabella li dispone per
/// analita e data, il grafico segue un singolo analita nel tempo. Costruirli
/// da un'unica lettura evita che le due viste possano discordare.
library;

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../../../features/parsing/analyte_catalog.dart';
import '../../../features/parsing/models.dart';
import '../database.dart';
import '../tables.dart';

/// Una misura collocata nel tempo.
class MeasurementPoint {
  const MeasurementPoint({
    required this.date,
    required this.reportId,
    required this.measurementId,
    this.value,
    this.rawValue,
    this.refLow,
    this.refHigh,
    this.refKind = StoredReferenceKind.none,
    this.refRaw,
    this.note,
  });

  final DateTime date;
  final int reportId;
  final int measurementId;
  final double? value;
  final String? rawValue;
  final double? refLow;
  final double? refHigh;
  final StoredReferenceKind refKind;
  final String? refRaw;
  final String? note;

  /// Un riferimento "desiderabile" è un obiettivo clinico, non un limite di
  /// normalità: non deve colorare il valore come se fosse patologico.
  bool get isDesirable =>
      refKind == StoredReferenceKind.desirableUpper ||
      refKind == StoredReferenceKind.desirableLower;

  ValueFlag get flag {
    final v = value;
    if (v == null || refKind == StoredReferenceKind.none) {
      return ValueFlag.unknown;
    }
    // Un obiettivo terapeutico superato va mostrato, ma con uno stato suo:
    // non è un esito fuori norma di laboratorio.
    if (isDesirable) {
      if (refHigh != null && v > refHigh!) return ValueFlag.aboveTarget;
      if (refLow != null && v < refLow!) return ValueFlag.belowTarget;
      return ValueFlag.normal;
    }
    if (refLow != null && v < refLow!) return ValueFlag.low;
    if (refHigh != null && v > refHigh!) return ValueFlag.high;
    return ValueFlag.normal;
  }

  String get display => value != null
      ? _formatNumber(value!)
      : (rawValue ?? '');

  /// Intervallo ricostruito, non il testo grezzo del referto.
  ///
  /// Sui referti fotografati il testo originale può essere sgranato (`40 52`
  /// con il trattino perso): mostrare quello farebbe dubitare di un dato che
  /// l'applicazione ha interpretato correttamente. Si mostra quindi ciò che
  /// l'app usa davvero per stabilire se il valore è nella norma.
  String get referenceLabel {
    if (refLow != null && refHigh != null) {
      return '${_formatNumber(refLow!)} - ${_formatNumber(refHigh!)}';
    }
    if (refHigh != null) return '< ${_formatNumber(refHigh!)}';
    if (refLow != null) return '> ${_formatNumber(refLow!)}';
    return refRaw ?? '';
  }
}

/// Tutti i valori di un analita per un paziente, in ordine di tempo.
class AnalyteSeries {
  AnalyteSeries({
    required this.canonicalKey,
    required this.displayName,
    required this.unit,
    required this.group,
    required this.points,
  });

  final String canonicalKey;
  final String displayName;

  /// L'unità fa parte dell'identità della serie: lo stesso analita misurato
  /// in unità diverse produce due serie separate, non una spezzata.
  final String unit;

  final String group;

  /// Ordinati per data crescente.
  final List<MeasurementPoint> points;

  MeasurementPoint? get latest => points.isEmpty ? null : points.last;

  bool get isNumeric => points.any((p) => p.value != null);

  /// Differenza rispetto alla misura precedente, se ce ne sono almeno due.
  double? get lastDelta {
    final numeric = points.where((p) => p.value != null).toList();
    if (numeric.length < 2) return null;
    return numeric.last.value! - numeric[numeric.length - 2].value!;
  }

  String get label => unit.isEmpty ? displayName : '$displayName ($unit)';

  /// Intervallo di riferimento ricorrente fra le misure della serie.
  ///
  /// Serve alle misure che ne sono prive. Il riconoscimento da foto perde
  /// spesso proprio la colonna dell'intervallo, e la perde sulla stessa riga
  /// in cui sbaglia il valore: sono lo stesso difetto di lettura. Senza un
  /// riferimento non c'è nulla contro cui giudicare la cifra, e l'errore
  /// resta invisibile proprio dove è più probabile.
  ///
  /// L'inferenza regge perché la serie è già definita da analita **e** unità:
  /// i punti a confronto misurano la stessa cosa nella stessa scala, e gli
  /// intervalli di laboratorio per un dato esame sono stabili nel tempo. Si
  /// prende la coppia più frequente, non la più recente, così un singolo
  /// referto letto male non detta il riferimento a tutti gli altri.
  ({double low, double high})? get typicalReference {
    final counts = <({double low, double high}), int>{};
    for (final p in points) {
      final low = p.refLow;
      final high = p.refHigh;
      if (low == null || high == null || high <= low) continue;
      if (p.isDesirable) continue;
      final pair = (low: low, high: high);
      counts[pair] = (counts[pair] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;

    var best = counts.entries.first;
    for (final e in counts.entries) {
      if (e.value > best.value) best = e;
    }
    return best.key;
  }
}

/// Dati pronti per la vista tabellare: analiti in riga, prelievi in colonna.
class ResultsTable {
  const ResultsTable({required this.dates, required this.series});

  /// Date dei prelievi, dalla più recente alla più antica.
  final List<DateTime> dates;

  final List<AnalyteSeries> series;

  bool get isEmpty => series.isEmpty;

  /// Serie raggruppate per pannello (Emocromo, Lipidi, ...), in ordine.
  Map<String, List<AnalyteSeries>> get byGroup {
    final map = <String, List<AnalyteSeries>>{};
    for (final s in series) {
      map.putIfAbsent(s.group, () => []).add(s);
    }
    return map;
  }

  /// Valore di un analita a una certa data, `null` se non misurato.
  MeasurementPoint? at(AnalyteSeries series, DateTime date) {
    for (final p in series.points) {
      if (p.date == date) return p;
    }
    return null;
  }
}

class SeriesRepository {
  const SeriesRepository(this._db);

  final AppDatabase _db;

  /// Ricostruisce la tabella completa di un paziente.
  ///
  /// Si legge tutto in una volta e si compone in memoria: per un archivio
  /// personale i volumi sono nell'ordine delle migliaia di righe, e avere
  /// l'insieme completo permette di allineare le colonne senza query annidate.
  Stream<ResultsTable> watchTable(int patientId) {
    final measurements = _db.select(_db.measurements).join([
      innerJoin(_db.reports, _db.reports.id.equalsExp(_db.measurements.reportId)),
    ])..where(_db.measurements.patientId.equals(patientId));

    // Le unioni manuali entrano nel flusso: modificarle deve aggiornare
    // subito tabella e grafici, senza dover riaprire la scheda.
    return Rx.combineLatest2(
      measurements.watch(),
      _db.select(_db.analyteAliases).watch(),
      _buildTable,
    );
  }

  Future<ResultsTable> loadTable(int patientId) async {
    final query = _db.select(_db.measurements).join([
      innerJoin(_db.reports, _db.reports.id.equalsExp(_db.measurements.reportId)),
    ])..where(_db.measurements.patientId.equals(patientId));

    return _buildTable(
      await query.get(),
      await _db.select(_db.analyteAliases).get(),
    );
  }

  /// Registra che una serie va letta come un'altra.
  Future<void> mergeSeries({
    required AnalyteSeries source,
    required AnalyteSeries target,
  }) async {
    if (source.canonicalKey == target.canonicalKey) return;

    await _db.into(_db.analyteAliases).insertOnConflictUpdate(
      AnalyteAliasesCompanion.insert(
        fromKey: source.canonicalKey,
        toKey: target.canonicalKey,
        fromLabel: source.label,
        toLabel: target.label,
      ),
    );
  }

  /// Corregge il valore di una misura già archiviata.
  ///
  /// Serve quando un errore di lettura è sfuggito alla revisione: reimportare
  /// il referto per una cifra sbagliata significherebbe rifare tutto il
  /// percorso e rischiare di duplicare il prelievo. La misura resta la stessa
  /// riga, quindi conserva il collegamento al referto di origine e il suo
  /// intervallo di riferimento, e viene marcata come rivista.
  Future<void> updateMeasurementValue({
    required int measurementId,
    required double? value,
  }) async {
    await (_db.update(_db.measurements)
          ..where((m) => m.id.equals(measurementId)))
        .write(
      MeasurementsCompanion(
        value: Value(value),
        reviewed: const Value(true),
      ),
    );
  }

  /// Elimina una singola misura, lasciando intatto il resto del referto.
  Future<void> deleteMeasurement(int measurementId) async {
    await (_db.delete(_db.measurements)
          ..where((m) => m.id.equals(measurementId)))
        .go();
  }

  /// Annulla un'unione: le due serie tornano separate.
  Future<void> undoMerge(String fromKey) async {
    await (_db.delete(_db.analyteAliases)
          ..where((a) => a.fromKey.equals(fromKey)))
        .go();
  }

  Stream<List<AnalyteAlias>> watchAliases() =>
      _db.select(_db.analyteAliases).watch();

  ResultsTable _buildTable(
    List<TypedResult> rows,
    List<AnalyteAlias> aliases,
  ) {
    // Le corrispondenze possono incatenarsi (A letto come B, B come C): si
    // segue la catena fino alla chiave finale, con un limite per non restare
    // bloccati se qualcuno crea un anello.
    final redirect = {for (final a in aliases) a.fromKey: a.toKey};
    String resolve(String key) {
      var current = key;
      for (var hops = 0; hops < 8; hops++) {
        final next = redirect[current];
        if (next == null || next == current) return current;
        current = next;
      }
      return current;
    }
    return _composeTable(rows, resolve);
  }

  ResultsTable _composeTable(
    List<TypedResult> rows,
    String Function(String) resolve,
  ) {
    final grouped = <String, List<MeasurementPoint>>{};
    final meta = <String, ({String name, String unit})>{};
    final dates = <DateTime>{};

    for (final row in rows) {
      final m = row.readTable(_db.measurements);
      final r = row.readTable(_db.reports);
      final date = DateTime(r.examDate.year, r.examDate.month, r.examDate.day);
      dates.add(date);

      // La chiave effettiva tiene conto delle unioni manuali: due letture
      // diverse dello stesso esame confluiscono qui in una sola serie.
      final key = resolve(m.canonicalKey);

      grouped.putIfAbsent(key, () => []).add(
        MeasurementPoint(
          date: date,
          reportId: r.id,
          measurementId: m.id,
          value: m.value,
          rawValue: m.rawValue,
          refLow: m.refLow,
          refHigh: m.refHigh,
          refKind: m.refKind,
          refRaw: m.refRaw,
          note: m.note,
        ),
      );
      // Nome e unità sono quelli della chiave di destinazione: se una lettura
      // storpiata confluisce in una corretta, deve sparire dalla vista.
      if (key == m.canonicalKey || !meta.containsKey(key)) {
        meta[key] = (name: m.displayName, unit: m.unit);
      }
    }

    final series = <AnalyteSeries>[];
    for (final entry in grouped.entries) {
      final points = entry.value..sort((a, b) => a.date.compareTo(b.date));
      final info = meta[entry.key]!;
      series.add(
        AnalyteSeries(
          canonicalKey: entry.key,
          displayName: info.name,
          unit: info.unit,
          group: AnalyteCatalog.groupFor(info.name),
          points: points,
        ),
      );
    }

    // Ordine stabile: prima per gruppo secondo il catalogo, poi per nome,
    // così la tabella non cambia disposizione fra un'apertura e l'altra.
    series.sort((a, b) {
      final g = _groupRank(a.group).compareTo(_groupRank(b.group));
      if (g != 0) return g;
      final n = a.displayName.compareTo(b.displayName);
      return n != 0 ? n : a.unit.compareTo(b.unit);
    });

    final sortedDates = dates.toList()..sort((a, b) => b.compareTo(a));
    return ResultsTable(dates: sortedDates, series: series);
  }

  /// Serie di un singolo analita, per il grafico.
  Stream<AnalyteSeries?> watchSeries(int patientId, String canonicalKey) {
    return watchTable(patientId).map((table) {
      for (final s in table.series) {
        if (s.canonicalKey == canonicalKey) return s;
      }
      return null;
    });
  }

  static const _groupOrder = <String>[
    'Emocromo',
    'Formula leucocitaria',
    'Infiammazione',
    'Lipidi',
    'Fegato',
    'Rene',
    'Metabolismo',
    'Tiroide',
    'Marziale',
    'Vitamine',
    'Elettroliti',
    'Altro',
  ];

  static int _groupRank(String group) {
    final i = _groupOrder.indexOf(group);
    return i < 0 ? _groupOrder.length : i;
  }
}

String _formatNumber(double v) {
  if (v == v.roundToDouble() && v.abs() < 1e9) return v.toStringAsFixed(0);
  return v.toString();
}
