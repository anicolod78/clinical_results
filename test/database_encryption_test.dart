import 'dart:io';
import 'dart:typed_data';

import 'package:clinical_results/core/security/pin_crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Verifica che il database sia realmente cifrato sul supporto.
///
/// Il test lavora direttamente sull'API di sqlite3, senza drift, per poter
/// ispezionare il file prodotto byte per byte: è l'unico modo per accertare
/// che i dati sanitari non finiscano in chiaro sul dispositivo, invece di
/// limitarsi a dare per buona la configurazione.
void main() {
  late Directory temp;
  late String dbPath;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('clinical_enc_test');
    dbPath = '${temp.path}/test.db';
  });

  tearDown(() {
    // Su Windows il file resta agganciato se un test fallisce prima della
    // chiusura: la pulizia non deve mascherare l'errore vero.
    try {
      temp.deleteSync(recursive: true);
    } on FileSystemException {
      // ignorata di proposito
    }
  });

  String pragmaKey(String hex) => "PRAGMA hexkey = '$hex';";

  test('la build di SQLite in uso supporta la cifratura', () {
    final db = sqlite3.open(dbPath);
    addTearDown(db.close);
    // Su SQLite standard questo PRAGMA non restituisce nulla: se il test
    // fallisce, la configurazione hooks/user_defines non è attiva e l'app
    // starebbe scrivendo in chiaro.
    expect(
      db.select('PRAGMA cipher;'),
      isNotEmpty,
      reason: 'manca il supporto SQLite3 Multiple Ciphers',
    );
  });

  test('i dati non sono leggibili in chiaro nel file', () {
    final key = PinCrypto.toHexKey(PinCrypto.randomBytes(32));

    final db = sqlite3.open(dbPath);
    db.execute(pragmaKey(key));
    db.execute('CREATE TABLE patients (id INTEGER PRIMARY KEY, name TEXT);');
    db.execute("INSERT INTO patients (name) VALUES ('ROSSI MARIO');");
    db.execute("INSERT INTO patients (name) VALUES ('RSSMRA80A01H501U');");
    db.close();

    final bytes = File(dbPath).readAsBytesSync();
    expect(_contains(bytes, 'ROSSI MARIO'), isFalse,
        reason: 'il nome del paziente è leggibile nel file');
    expect(_contains(bytes, 'RSSMRA80A01H501U'), isFalse,
        reason: 'il codice fiscale è leggibile nel file');
    // In un file cifrato sparisce persino l'intestazione standard di SQLite.
    expect(_contains(bytes, 'SQLite format 3'), isFalse);
  });

  test('con la chiave giusta i dati si rileggono, con quella sbagliata no', () {
    final good = PinCrypto.toHexKey(PinCrypto.randomBytes(32));
    final bad = PinCrypto.toHexKey(PinCrypto.randomBytes(32));

    var db = sqlite3.open(dbPath);
    db.execute(pragmaKey(good));
    db.execute('CREATE TABLE measurements (id INTEGER PRIMARY KEY, v REAL);');
    db.execute('INSERT INTO measurements (v) VALUES (14.4);');
    db.close();

    db = sqlite3.open(dbPath);
    db.execute(pragmaKey(good));
    expect(db.select('SELECT v FROM measurements;').single['v'], 14.4);
    db.close();

    db = sqlite3.open(dbPath);
    db.execute(pragmaKey(bad));
    expect(
      () => db.select('SELECT v FROM measurements;'),
      throwsA(isA<SqliteException>()),
      reason: 'una chiave errata non deve dare accesso ai dati',
    );
    db.close();
  });

  test('senza chiave il database non si apre affatto', () {
    final key = PinCrypto.toHexKey(PinCrypto.randomBytes(32));
    var db = sqlite3.open(dbPath);
    db.execute(pragmaKey(key));
    db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY);');
    db.close();

    db = sqlite3.open(dbPath);
    expect(
      () => db.select('SELECT * FROM t;'),
      throwsA(isA<SqliteException>()),
    );
    db.close();
  });

  test('il PIN apre il database di cui non conosce direttamente la chiave', () {
    // Percorso completo: PIN -> chiave incapsulata -> chiave dati -> database.
    final vault = PinCrypto.createVault('428913');

    var db = sqlite3.open(dbPath);
    db.execute(pragmaKey(PinCrypto.toHexKey(vault.dek)));
    db.execute('CREATE TABLE t (v TEXT);');
    db.execute("INSERT INTO t VALUES ('emoglobina 14.4');");
    db.close();

    // Riavvio dell'app: si riparte dal solo blob salvato e dal PIN digitato.
    final stored = WrappedKey.fromJson(vault.wrapped.toJson());
    final dek = PinCrypto.unwrapKey(stored, '428913');

    db = sqlite3.open(dbPath);
    db.execute(pragmaKey(PinCrypto.toHexKey(dek)));
    expect(db.select('SELECT v FROM t;').single['v'], 'emoglobina 14.4');
    db.close();
  });
}

bool _contains(Uint8List haystack, String needle) {
  final n = needle.codeUnits;
  outer:
  for (var i = 0; i + n.length <= haystack.length; i++) {
    for (var j = 0; j < n.length; j++) {
      if (haystack[i + j] != n[j]) continue outer;
    }
    return true;
  }
  return false;
}
