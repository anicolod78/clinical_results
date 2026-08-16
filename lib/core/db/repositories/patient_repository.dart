/// Accesso all'anagrafica pazienti.
library;

import 'package:drift/drift.dart';

import '../database.dart';

class PatientRepository {
  const PatientRepository(this._db);

  final AppDatabase _db;

  Stream<List<Patient>> watchAll() {
    return (_db.select(_db.patients)
          ..orderBy([(p) => OrderingTerm(expression: p.fullName)]))
        .watch();
  }

  Future<List<Patient>> all() {
    return (_db.select(_db.patients)
          ..orderBy([(p) => OrderingTerm(expression: p.fullName)]))
        .get();
  }

  Future<Patient?> byId(int id) {
    return (_db.select(_db.patients)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Cerca un paziente dal codice fiscale letto sul referto.
  ///
  /// È il modo più affidabile per riconoscere a chi appartiene un documento:
  /// il nome può essere scritto in forme diverse fra un laboratorio e l'altro,
  /// il codice fiscale no.
  Future<Patient?> byFiscalCode(String fiscalCode) {
    final normalized = fiscalCode.trim().toUpperCase();
    if (normalized.isEmpty) return Future.value(null);
    return (_db.select(_db.patients)
          ..where((p) => p.fiscalCode.equals(normalized)))
        .getSingleOrNull();
  }

  Future<int> create({
    required String fullName,
    String? fiscalCode,
    DateTime? birthDate,
    String? sex,
    String? note,
  }) {
    return _db.into(_db.patients).insert(
      PatientsCompanion.insert(
        fullName: fullName.trim(),
        fiscalCode: Value(fiscalCode?.trim().toUpperCase()),
        birthDate: Value(birthDate),
        sex: Value(sex),
        note: Value(note),
      ),
    );
  }

  Future<void> update(Patient patient) =>
      _db.update(_db.patients).replace(patient);

  /// Elimina il paziente e, per effetto dei vincoli, referti e misure.
  Future<void> delete(int id) async {
    await (_db.delete(_db.patients)..where((p) => p.id.equals(id))).go();
  }

  /// Numero di referti archiviati per ciascun paziente.
  Future<Map<int, int>> reportCounts() async {
    final count = _db.reports.id.count();
    final query = _db.selectOnly(_db.reports)
      ..addColumns([_db.reports.patientId, count])
      ..groupBy([_db.reports.patientId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.reports.patientId)!: row.read(count) ?? 0,
    };
  }
}
