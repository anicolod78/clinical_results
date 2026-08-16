/// Apertura del database nel browser.
///
/// Il database viene aperto nel contesto JavaScript principale e non in un
/// web worker. `WasmDatabase.open` delega quasi sempre a un worker, e in quel
/// caso drift non invoca la funzione di inizializzazione: nessun PRAGMA
/// applicato all'apertura verrebbe eseguito. Aprendo direttamente si perde
/// l'esecuzione fuori dal thread della UI, ma si ottiene il controllo
/// completo su come il database viene inizializzato.
library;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/wasm.dart';

const _databaseName = 'clinical_results';
const _path = '/clinical_results.db';
const _vfsName = 'indexeddb';

/// Nome che SQLite3 Multiple Ciphers assegna al proprio involucro cifrante
/// attorno a un file system virtuale già registrato.
const _encryptedVfsName = 'multipleciphers-$_vfsName';

final _wasmUri = Uri.parse('sqlite3mc.wasm');

/// Esito dell'apertura, con l'indicazione se la cifratura sia attiva.
///
/// Viene esposto perché l'interfaccia deve poter avvertire l'utente quando i
/// dati non sono protetti: su dati sanitari il silenzio non è accettabile.
class WebDatabaseOpening {
  const WebDatabaseOpening({required this.executor, required this.encrypted});

  final QueryExecutor executor;
  final bool encrypted;
}

WebDatabaseOpening? _lastOpening;

/// `true` se l'ultimo database aperto nel browser è cifrato.
///
/// Nel browser la cifratura non è garantita: dipende da quali file system
/// virtuali il modulo WebAssembly riesce ad avvolgere con lo strato cifrante.
/// L'esito viene quindi dichiarato invece che dato per scontato.
bool get databaseIsEncrypted => _lastOpening?.encrypted ?? false;

Future<QueryExecutor> openEncryptedDatabase(String hexKey) async {
  final sqlite3 = await WasmSqlite3.loadFromUrl(_wasmUri);
  final fileSystem = await IndexedDbFileSystem.open(dbName: _databaseName);
  sqlite3.registerVirtualFileSystem(fileSystem, makeDefault: true);

  // Primo tentativo: il file system virtuale avvolto dallo strato cifrante.
  // Se SQLite3 Multiple Ciphers ha creato l'involucro, il database è cifrato
  // esattamente come su Android.
  final encrypted = _tryOpen(sqlite3, hexKey, vfs: _encryptedVfsName);
  if (encrypted != null) {
    _lastOpening = WebDatabaseOpening(
      executor: WasmDatabase.opened(encrypted),
      encrypted: true,
    );
    return _lastOpening!.executor;
  }

  // Secondo tentativo: il file system predefinito, che conserva l'accesso
  // all'archivio se una versione futura non creasse più l'involucro.
  //
  // Qui la cifratura viene dichiarata **non** dimostrata anche quando
  // `PRAGMA hexkey` non solleva eccezioni. SQLite3 Multiple Ciphers accetta la
  // chiave in silenzio pure dove non la applica, e su dati sanitari una
  // rassicurazione falsa è l'errore peggiore: meglio un avviso di troppo che
  // un archivio creduto protetto e leggibile. Con la versione attuale questa
  // via non viene comunque percorsa, perché la prima riesce.
  final direct = _tryOpen(sqlite3, hexKey, vfs: null);
  if (direct != null) {
    _lastOpening = WebDatabaseOpening(
      executor: WasmDatabase.opened(direct),
      encrypted: false,
    );
    return _lastOpening!.executor;
  }

  // Nessuna delle due vie applica la chiave: la cifratura su IndexedDB non è
  // disponibile in questa versione. Si apre in chiaro e lo si dichiara, così
  // l'interfaccia può avvertire che la piattaforma Web non va usata con dati
  // reali.
  final fallback = sqlite3.open(_path);
  fallback.execute('PRAGMA foreign_keys = ON;');
  _lastOpening = WebDatabaseOpening(
    executor: WasmDatabase.opened(fallback),
    encrypted: false,
  );
  return _lastOpening!.executor;
}

/// Apre e prova ad applicare la chiave, restituendo `null` se non riesce.
CommonDatabase? _tryOpen(
  WasmSqlite3 sqlite3,
  String hexKey, {
  required String? vfs,
}) {
  CommonDatabase? db;
  try {
    db = sqlite3.open(_path, vfs: vfs);
    db.execute("PRAGMA hexkey = '$hexKey';");
    // La chiave viene accettata in silenzio anche quando non serve: solo una
    // lettura effettiva dimostra che il database è utilizzabile.
    db.execute('PRAGMA user_version;');
    db.execute('PRAGMA foreign_keys = ON;');
    return db;
  } catch (e) {
    debugPrint('[web] apertura con vfs "${vfs ?? 'predefinito'}" fallita: $e');
    db?.close();
    return null;
  }
}

Future<void> deleteEncryptedDatabase() async {
  final fileSystem = await IndexedDbFileSystem.open(dbName: _databaseName);
  if (fileSystem.xAccess(_path, 0) != 0) {
    fileSystem.xDelete(_path, 0);
  }
  _lastOpening = null;
}
