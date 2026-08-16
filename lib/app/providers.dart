/// Provider condivisi dell'applicazione.
///
/// I repository dipendono dal database, che esiste solo a sessione sbloccata:
/// leggerli mentre l'app è bloccata è un errore di programmazione, non una
/// condizione da gestire, quindi solleva un'eccezione invece di restituire
/// silenziosamente un archivio vuoto.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../core/db/repositories/patient_repository.dart';
import '../core/db/repositories/report_repository.dart';
import '../core/db/repositories/series_repository.dart';
import '../features/import/import_service.dart';
import 'session.dart';

/// Servizio di acquisizione e lettura dei referti.
///
/// È unico per l'intera applicazione perché il motore di riconoscimento
/// mantiene risorse native che conviene creare una sola volta.
final importServiceProvider = Provider<ImportService>((ref) {
  final service = ImportService();
  ref.onDispose(service.dispose);
  return service;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionUnlocked) {
    throw StateError('Database non disponibile: la sessione è bloccata.');
  }
  return session.database;
});

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => PatientRepository(ref.watch(databaseProvider)),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(databaseProvider)),
);

final seriesRepositoryProvider = Provider<SeriesRepository>(
  (ref) => SeriesRepository(ref.watch(databaseProvider)),
);

/// Elenco dei pazienti.
final patientsProvider = StreamProvider<List<Patient>>(
  (ref) => ref.watch(patientRepositoryProvider).watchAll(),
);

/// Paziente attualmente selezionato.
final selectedPatientProvider = StateProvider<int?>((ref) => null);

/// Referti del paziente selezionato.
final patientReportsProvider = StreamProvider.family<List<Report>, int>(
  (ref, patientId) =>
      ref.watch(reportRepositoryProvider).watchForPatient(patientId),
);

/// Tabella completa dei risultati del paziente selezionato.
final resultsTableProvider = StreamProvider.family<ResultsTable, int>(
  (ref, patientId) => ref.watch(seriesRepositoryProvider).watchTable(patientId),
);

/// Unioni manuali fra serie, registrate dall'utente.
final aliasesProvider = StreamProvider<List<AnalyteAlias>>(
  (ref) => ref.watch(seriesRepositoryProvider).watchAliases(),
);
