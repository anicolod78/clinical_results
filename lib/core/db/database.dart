/// Database cifrato dell'applicazione.
library;

import 'package:drift/drift.dart';

import 'connection/unsupported.dart'
    if (dart.library.io) 'connection/native.dart'
    if (dart.library.js_interop) 'connection/web.dart' as impl;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Patients, Reports, Measurements, AnalyteAliases])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Apre il database con la chiave dati ottenuta sbloccando il PIN.
  static Future<AppDatabase> open(String keyLiteral) async {
    return AppDatabase(await impl.openEncryptedDatabase(keyLiteral));
  }

  /// Cancella definitivamente l'archivio.
  static Future<void> destroy() => impl.deleteEncryptedDatabase();

  /// Se il database attualmente aperto è cifrato.
  ///
  /// Va interrogato dopo l'apertura: nel browser l'esito si conosce solo a
  /// quel punto. Serve a dirlo apertamente all'utente, perché un archivio
  /// sanitario non protetto che si comporta come se lo fosse è peggio di uno
  /// dichiaratamente non protetto.
  static bool get isEncrypted => impl.databaseIsEncrypted;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      // Versione 2: unione manuale delle serie.
      //
      // La migrazione si limita a creare la nuova tabella. Nessuna colonna
      // esistente viene toccata e nessuna misura riscritta: su un archivio
      // che contiene referti reali una migrazione distruttiva non avrebbe
      // modo di essere annullata.
      if (from < 2) {
        await m.createTable(analyteAliases);
      }
    },
    onCreate: (m) async {
      await m.createAll();
      // Le serie storiche si leggono sempre per paziente e analita: senza
      // questo indice ogni grafico farebbe una scansione completa.
      await customStatement(
        'CREATE INDEX idx_measure_series '
        'ON measurements (patient_id, canonical_key)',
      );
      await customStatement(
        'CREATE INDEX idx_report_patient_date '
        'ON reports (patient_id, exam_date)',
      );
    },
  );
}
