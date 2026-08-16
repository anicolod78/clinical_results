import 'package:drift/drift.dart';

/// Segnaposto per piattaforme senza implementazione: non viene mai compilato
/// perché l'import condizionale sceglie sempre la versione nativa o web.
Future<QueryExecutor> openEncryptedDatabase(String keyLiteral) {
  throw UnsupportedError('Piattaforma non supportata');
}

Future<void> deleteEncryptedDatabase() {
  throw UnsupportedError('Piattaforma non supportata');
}

bool get databaseIsEncrypted => false;
