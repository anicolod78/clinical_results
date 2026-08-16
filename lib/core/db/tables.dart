/// Schema del database.
///
/// L'intero file di database è cifrato (SQLite3 Multiple Ciphers), quindi le
/// colonne possono restare in chiaro: non serve cifrare i singoli campi, che
/// impedirebbe di ordinare e filtrare lato database.
library;

import 'package:drift/drift.dart';

/// Origine da cui è stato acquisito un referto.
enum SourceKind { pdf, image, manual }

/// Tipo di intervallo di riferimento, allineato a `ReferenceKind` del parser.
enum StoredReferenceKind {
  range,
  upperBound,
  lowerBound,
  desirableUpper,
  desirableLower,
  none,
}

@DataClassName('Patient')
class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get fullName => text().withLength(min: 1, max: 120)();

  /// Permette di riconoscere automaticamente il paziente all'importazione:
  /// i referti italiani riportano quasi sempre il codice fiscale.
  TextColumn get fiscalCode => text().nullable().withLength(max: 16)();

  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get sex => text().nullable().withLength(max: 1)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Report')
class Reports extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();

  /// Data del prelievo: è l'asse temporale di tabelle e grafici.
  DateTimeColumn get examDate => dateTime()();

  DateTimeColumn get importedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get laboratory => text().nullable()();
  TextColumn get reportNumber => text().nullable()();
  TextColumn get sourceKind => textEnum<SourceKind>()();
  TextColumn get sourceName => text().nullable()();

  /// Documento originale conservato dentro il database, quindi cifrato come
  /// tutto il resto: tenerlo come file separato lo lascerebbe in chiaro nella
  /// memoria del dispositivo.
  BlobColumn get originalDocument => blob().nullable()();

  /// Testo estratto, utile per rivedere l'origine di un valore.
  TextColumn get rawText => text().nullable()();

  TextColumn get note => text().nullable()();
}

/// Unione manuale di due serie storiche.
///
/// Serve quando lo stesso esame è stato letto in due modi diversi e le
/// riparazioni automatiche non bastano: un nome storpiato dal riconoscimento
/// ottico, un'unità irriconoscibile. Le misure restano come sono state
/// acquisite; qui si registra soltanto che una chiave va letta come un'altra.
///
/// Tenere separata la correzione dal dato ha tre conseguenze utili: il valore
/// originale resta verificabile contro il documento, l'unione si può
/// annullare, e vale anche per i referti che verranno importati in futuro con
/// lo stesso difetto di lettura.
@DataClassName('AnalyteAlias')
class AnalyteAliases extends Table {
  /// Chiave da assorbire.
  TextColumn get fromKey => text()();

  /// Chiave in cui confluisce.
  TextColumn get toKey => text()();

  /// Nome mostrato al momento dell'unione, per poterla descrivere in
  /// elenco senza dover ricostruire la serie.
  TextColumn get fromLabel => text()();
  TextColumn get toLabel => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {fromKey};
}

@DataClassName('Measurement')
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get reportId =>
      integer().references(Reports, #id, onDelete: KeyAction.cascade)();

  /// Ripetuto rispetto al referto per interrogare le serie storiche di un
  /// paziente senza join, che è l'accesso più frequente dell'app.
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();

  /// Chiave di confronto nel tempo, comprensiva di unità di misura.
  TextColumn get canonicalKey => text()();

  TextColumn get displayName => text()();
  TextColumn get rawName => text()();

  RealColumn get value => real().nullable()();

  /// Esito non numerico (`assente`, `negativo`).
  TextColumn get rawValue => text().nullable()();

  TextColumn get unit => text().withDefault(const Constant(''))();

  RealColumn get refLow => real().nullable()();
  RealColumn get refHigh => real().nullable()();
  TextColumn get refKind => textEnum<StoredReferenceKind>()
      .withDefault(Constant(StoredReferenceKind.none.name))();
  TextColumn get refRaw => text().nullable()();

  TextColumn get section => text().nullable()();
  TextColumn get panel => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Segna i valori rivisti dall'utente, per distinguerli da quelli
  /// accettati così come estratti.
  BoolColumn get reviewed => boolean().withDefault(const Constant(false))();
}
