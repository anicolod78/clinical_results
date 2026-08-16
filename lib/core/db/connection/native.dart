/// Apertura del database cifrato su Android.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

const _fileName = 'clinical_results.db';

Future<File> _databaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, _fileName));
}

/// Apre il database applicando la chiave prima di qualsiasi altra operazione.
///
/// [hexKey] è la chiave dati in esadecimale: `PRAGMA hexkey` la usa come
/// materiale di chiave grezzo, senza applicarvi una seconda derivazione.
Future<QueryExecutor> openEncryptedDatabase(String hexKey) async {
  final file = await _databaseFile();
  return NativeDatabase.createInBackground(
    file,
    setup: (database) {
      // Se la build in uso non avesse il supporto alla cifratura, il PRAGMA
      // verrebbe ignorato in silenzio e il database resterebbe in chiaro:
      // meglio interrompere subito che archiviare dati sanitari non protetti.
      _assertCipherAvailable(database);
      database.execute("PRAGMA hexkey = '$hexKey';");
      database.execute('PRAGMA foreign_keys = ON;');
    },
  );
}

void _assertCipherAvailable(CommonDatabase database) {
  final result = database.select('PRAGMA cipher;');
  if (result.isEmpty) {
    throw StateError(
      'La libreria SQLite in uso non supporta la cifratura. '
      'Verificare che il pubspec contenga hooks/user_defines con '
      'sqlite3.source: sqlite3mc.',
    );
  }
}

/// Elimina il database.
///
/// Usata dalla cancellazione dei dati dopo troppi tentativi di PIN errati.
Future<void> deleteEncryptedDatabase() async {
  final file = await _databaseFile();
  if (file.existsSync()) await file.delete();
}

/// Su Android la cifratura è sempre attiva.
///
/// L'apertura verifica `PRAGMA cipher` e interrompe se la libreria non
/// supporta la cifratura, quindi un database aperto è necessariamente
/// cifrato: non esiste il caso in cui l'app funzioni senza protezione.
bool get databaseIsEncrypted => true;
