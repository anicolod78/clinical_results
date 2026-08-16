/// Archiviazione dei referti e delle misure che ne derivano.
library;

import 'package:drift/drift.dart';

import '../../../features/parsing/models.dart';
import '../database.dart';
import '../tables.dart';

/// Referto già esistente per lo stesso paziente e la stessa data.
class DuplicateReport {
  const DuplicateReport(this.report, this.measurementCount);

  final Report report;
  final int measurementCount;
}

class ReportRepository {
  const ReportRepository(this._db);

  final AppDatabase _db;

  Stream<List<Report>> watchForPatient(int patientId) {
    return (_db.select(_db.reports)
          ..where((r) => r.patientId.equals(patientId))
          ..orderBy([
            (r) => OrderingTerm(expression: r.examDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<Report?> byId(int id) =>
      (_db.select(_db.reports)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Verifica se esiste già un referto per lo stesso prelievo.
  ///
  /// Reimportare due volte lo stesso documento raddoppierebbe i punti sul
  /// grafico, dando l'impressione di esami che non ci sono stati.
  Future<DuplicateReport?> findDuplicate({
    required int patientId,
    required DateTime examDate,
    String? reportNumber,
  }) async {
    final day = DateTime(examDate.year, examDate.month, examDate.day);
    final nextDay = day.add(const Duration(days: 1));

    final query = _db.select(_db.reports)
      ..where((r) =>
          r.patientId.equals(patientId) &
          r.examDate.isBiggerOrEqualValue(day) &
          r.examDate.isSmallerThanValue(nextDay));

    final candidates = await query.get();
    if (candidates.isEmpty) return null;

    // Con il numero di referto il riconoscimento è certo; senza, ci si basa
    // sulla coincidenza della data del prelievo.
    final match = reportNumber == null
        ? candidates.first
        : candidates.firstWhere(
            (r) => r.reportNumber == reportNumber,
            orElse: () => candidates.first,
          );

    final count = await _measurementCount(match.id);
    return DuplicateReport(match, count);
  }

  Future<int> _measurementCount(int reportId) async {
    final count = _db.measurements.id.count();
    final query = _db.selectOnly(_db.measurements)
      ..addColumns([count])
      ..where(_db.measurements.reportId.equals(reportId));
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// Salva un referto con le sue misure in un'unica transazione.
  ///
  /// [analytes] sono i valori già confermati dall'utente in revisione, non
  /// quelli grezzi del parser: nulla entra in archivio senza essere passato
  /// sotto gli occhi di chi importa.
  Future<int> save({
    required int patientId,
    required DateTime examDate,
    required List<ParsedAnalyte> analytes,
    required SourceKind sourceKind,
    String? sourceName,
    String? laboratory,
    String? reportNumber,
    Uint8List? originalDocument,
    String? rawText,
    String? note,
    bool reviewed = true,
  }) {
    return _db.transaction(() async {
      final reportId = await _db.into(_db.reports).insert(
        ReportsCompanion.insert(
          patientId: patientId,
          examDate: examDate,
          sourceKind: sourceKind,
          sourceName: Value(sourceName),
          laboratory: Value(laboratory),
          reportNumber: Value(reportNumber),
          originalDocument: Value(originalDocument),
          rawText: Value(rawText),
          note: Value(note),
        ),
      );

      await _db.batch((batch) {
        batch.insertAll(
          _db.measurements,
          analytes.map(
            (a) => MeasurementsCompanion.insert(
              reportId: reportId,
              patientId: patientId,
              canonicalKey: a.canonicalKey,
              displayName: a.displayName,
              rawName: a.rawName,
              value: Value(a.value),
              rawValue: Value(a.rawValue),
              unit: Value(a.unit),
              refLow: Value(a.reference.low),
              refHigh: Value(a.reference.high),
              refKind: Value(_mapKind(a.reference.kind)),
              refRaw: Value(a.reference.raw.isEmpty ? null : a.reference.raw),
              section: Value(a.section),
              panel: Value(a.panel),
              note: Value(a.note),
              reviewed: Value(reviewed),
            ),
          ),
        );
      });

      return reportId;
    });
  }

  Future<void> delete(int reportId) async {
    await (_db.delete(_db.reports)..where((r) => r.id.equals(reportId))).go();
  }

  Future<List<Measurement>> measurementsOf(int reportId) {
    return (_db.select(_db.measurements)
          ..where((m) => m.reportId.equals(reportId))
          ..orderBy([(m) => OrderingTerm(expression: m.id)]))
        .get();
  }

  static StoredReferenceKind _mapKind(ReferenceKind kind) =>
      switch (kind) {
        ReferenceKind.range => StoredReferenceKind.range,
        ReferenceKind.upperBound => StoredReferenceKind.upperBound,
        ReferenceKind.lowerBound => StoredReferenceKind.lowerBound,
        ReferenceKind.desirableUpper => StoredReferenceKind.desirableUpper,
        ReferenceKind.desirableLower => StoredReferenceKind.desirableLower,
        ReferenceKind.none => StoredReferenceKind.none,
      };
}
