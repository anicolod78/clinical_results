@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:clinical_results/core/security/pin_crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/wasm.dart';

/// Verifica che la cifratura del database funzioni davvero nel browser.
///
/// È l'unica piattaforma in cui la protezione dipende da quali file system
/// virtuali il modulo WebAssembly riesce ad avvolgere con lo strato cifrante.
/// Dedurlo dall'interfaccia non basta: qui si interroga il motore.
///
/// Richiede il server statico avviato su build/web, che espone sqlite3mc.wasm:
///
///   node tool/serve_web.js 8090
///   flutter test test/web_encryption_test.dart --platform chrome

/// Nome sotto cui `IndexedDbFileSystem` si registra.
const _vfsName = 'indexeddb';

/// Prefisso dell'involucro cifrante di SQLite3 Multiple Ciphers.
const _wrapped = 'multipleciphers-';

void main() {
  final wasmUri = Uri.parse('http://127.0.0.1:8090/sqlite3mc.wasm');
  final hexKey = PinCrypto.toHexKey(PinCrypto.randomBytes(32));

  test('il modulo WebAssembly include il supporto alla cifratura', () async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(wasmUri);
    final db = sqlite3.openInMemory();
    addTearDown(db.close);

    // Su una build standard questo PRAGMA non restituisce nulla.
    expect(
      db.select('PRAGMA cipher;'),
      isNotEmpty,
      reason: 'il wasm servito non è la variante con cifratura',
    );
  });

  test('il file system predefinito non supporta la cifratura', () async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(wasmUri);
    final fs = await IndexedDbFileSystem.open(dbName: 'prova_predefinito');
    sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

    final db = sqlite3.open('/prova.db');
    addTearDown(db.close);

    // Documenta il motivo per cui il codice di produzione non apre così: il
    // file system registrato, usato direttamente, rifiuta la chiave.
    expect(
      () => db.execute("PRAGMA hexkey = '$hexKey';"),
      throwsA(isA<SqliteException>()),
      reason: 'se questa via cominciasse a funzionare, il ripiego in '
          'web.dart potrebbe tornare a dichiarare la cifratura',
    );
  });

  test('la chiave si applica al file system avvolto', () async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(wasmUri);
    final fs = await IndexedDbFileSystem.open(dbName: 'prova_cifratura');
    sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

    // Lo stesso nome usato dal codice di produzione: l'involucro cifrante che
    // SQLite3 Multiple Ciphers crea attorno a ogni file system registrato.
    final db = sqlite3.open('/prova.db', vfs: '$_wrapped$_vfsName');
    addTearDown(db.close);

    db.execute("PRAGMA hexkey = '$hexKey';");
    db.execute('CREATE TABLE t (v TEXT);');
    db.execute("INSERT INTO t VALUES ('emoglobina 15.5');");
    expect(db.select('SELECT v FROM t;').single['v'], 'emoglobina 15.5');
  });

  test('i dati scritti non restano leggibili in chiaro', () async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(wasmUri);
    final fs = await IndexedDbFileSystem.open(dbName: 'prova_contenuto');
    sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

    final db = sqlite3.open('/contenuto.db', vfs: '$_wrapped$_vfsName');
    db.execute("PRAGMA hexkey = '$hexKey';");
    db.execute('CREATE TABLE patients (name TEXT);');
    db.execute("INSERT INTO patients VALUES ('ROSSI MARIO');");
    db.close();
    await fs.flush();

    final bytes = fs.xOpen(Sqlite3Filename('/contenuto.db'), 0).file;
    final size = bytes.xFileSize();
    final buffer = Uint8List(size);
    bytes.xRead(buffer, 0);
    bytes.xClose();

    final text = String.fromCharCodes(buffer);
    expect(text.contains('ROSSI MARIO'), isFalse,
        reason: 'il nome del paziente è leggibile nel file');
    expect(text.contains('SQLite format 3'), isFalse,
        reason: 'un file cifrato non conserva l intestazione di SQLite');
  });
}
