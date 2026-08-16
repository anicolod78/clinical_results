import 'dart:io';

import 'package:clinical_results/core/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Verifica l'aggiornamento dello schema su un archivio già popolato.
///
/// Sul dispositivo esiste un archivio con referti reali: una migrazione che
/// perdesse dati non sarebbe recuperabile, perché il database è cifrato e non
/// esiste copia di sicurezza. Il test costruisce un archivio nella versione
/// precedente, lo riempie, e controlla che dopo l'aggiornamento sia tutto al
/// suo posto.
void main() {
  late Directory temp;
  late String dbPath;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('clinical_migration');
    dbPath = '${temp.path}/archivio.db';
  });

  tearDown(() {
    try {
      temp.deleteSync(recursive: true);
    } on FileSystemException {
      // su Windows il file può restare agganciato: non maschera l'esito
    }
  });

  /// Ricava lo schema della versione 1 da quello attuale, togliendo la
  /// tabella introdotta dopo. Così il test resta valido se lo schema cambia,
  /// invece di dipendere da una copia scritta a mano che invecchia.
  Future<List<String>> schemaOfVersionOne() async {
    final probePath = '${temp.path}/probe.db';
    final probe = AppDatabase(NativeDatabase(File(probePath)));
    await probe.customSelect('SELECT 1').get();
    final rows = await probe
        .customSelect(
          "SELECT sql FROM sqlite_master "
          "WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final statements = rows
        .map((r) => r.read<String>('sql'))
        .where((sql) => !sql.contains('analyte_aliases'))
        .toList();
    await probe.close();
    return statements;
  }

  test('aggiornando alla versione 2 i dati restano intatti', () async {
    final ddl = await schemaOfVersionOne();

    // Archivio nella versione precedente, con dentro un paziente, un referto
    // e le sue misure.
    final legacy = sqlite3.open(dbPath);
    for (final statement in ddl) {
      legacy.execute(statement);
    }
    legacy.execute('PRAGMA user_version = 1;');
    legacy.execute(
      "INSERT INTO patients (id, full_name, fiscal_code, created_at) "
      "VALUES (1, 'ROSSI MARIO', 'RSSMRA80A01H501U', 0);",
    );
    legacy.execute(
      "INSERT INTO reports (id, patient_id, exam_date, imported_at, "
      "source_kind, report_number) "
      "VALUES (1, 1, 1690675200, 0, 'pdf', '11646696');",
    );
    legacy.execute(
      "INSERT INTO measurements (id, report_id, patient_id, canonical_key, "
      "display_name, raw_name, value, unit, ref_kind, reviewed) "
      "VALUES (1, 1, 1, 'emoglobina|g/dL', 'Emoglobina', 'Emoglobina', "
      "15.5, 'g/dL', 'range', 1);",
    );
    expect(legacy.select('PRAGMA user_version;').single['user_version'], 1);
    legacy.close();

    // Apertura con la versione corrente: la migrazione deve scattare.
    final upgraded = AppDatabase(NativeDatabase(File(dbPath)));
    final patients = await upgraded.select(upgraded.patients).get();
    final reports = await upgraded.select(upgraded.reports).get();
    final measurements = await upgraded.select(upgraded.measurements).get();
    final aliases = await upgraded.select(upgraded.analyteAliases).get();

    expect(patients, hasLength(1));
    expect(patients.single.fullName, 'ROSSI MARIO');
    expect(patients.single.fiscalCode, 'RSSMRA80A01H501U');

    expect(reports, hasLength(1));
    expect(reports.single.reportNumber, '11646696');

    expect(measurements, hasLength(1));
    expect(measurements.single.value, 15.5);
    expect(measurements.single.canonicalKey, 'emoglobina|g/dL');

    expect(aliases, isEmpty, reason: 'la nuova tabella nasce vuota');

    await upgraded.close();

    final version = sqlite3.open(dbPath);
    expect(version.select('PRAGMA user_version;').single['user_version'], 2);
    version.close();
  });

  test('un archivio nuovo nasce già nella versione corrente', () async {
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    await db.select(db.analyteAliases).get();
    await db.close();

    final raw = sqlite3.open(dbPath);
    expect(raw.select('PRAGMA user_version;').single['user_version'], 2);
    raw.close();
  });
}
