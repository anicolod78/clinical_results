/// Primitive crittografiche per la protezione del database.
///
/// Impianto:
///
///  1. alla prima configurazione si genera una chiave dati casuale di 32 byte
///     (DEK), che è quella con cui il database viene realmente cifrato;
///  2. dal PIN si deriva una chiave di protezione (KEK) con PBKDF2-HMAC-SHA256
///     e un sale casuale;
///  3. la DEK viene incapsulata con AES-256-GCM sotto la KEK e solo il
///     risultato viene salvato.
///
/// Due conseguenze importanti di questo schema:
///
///  * il PIN non è mai memorizzato, né in chiaro né come hash: la verifica
///    avviene per costruzione, perché con un PIN sbagliato l'autenticazione
///    GCM fallisce e la DEK non si ottiene;
///  * cambiare PIN richiede solo di re-incapsulare la stessa DEK, senza
///    ricifrare l'intero database.
///
/// Un PIN numerico ha entropia bassa (sei cifre sono un milione di
/// combinazioni): la derivazione lenta e il conteggio dei tentativi servono
/// proprio a compensare questo limite, insieme alla custodia del blob
/// incapsulato nel portachiavi di sistema.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Errore sollevato quando il PIN non permette di aprire la chiave.
class InvalidPinException implements Exception {
  const InvalidPinException();
  @override
  String toString() => 'InvalidPinException: PIN errato';
}

/// Chiave dati incapsulata, nella forma in cui viene conservata.
class WrappedKey {
  const WrappedKey({
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.iterations,
    this.version = 1,
  });

  final Uint8List salt;
  final Uint8List nonce;

  /// DEK cifrata, tag GCM incluso in coda.
  final Uint8List ciphertext;

  /// Numero di iterazioni PBKDF2 usate: memorizzato per poter alzare il
  /// parametro in futuro senza invalidare le installazioni esistenti.
  final int iterations;

  final int version;

  String toJson() => jsonEncode({
    'v': version,
    'it': iterations,
    'salt': base64Encode(salt),
    'nonce': base64Encode(nonce),
    'ct': base64Encode(ciphertext),
  });

  static WrappedKey fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return WrappedKey(
      version: map['v'] as int? ?? 1,
      iterations: map['it'] as int,
      salt: base64Decode(map['salt'] as String),
      nonce: base64Decode(map['nonce'] as String),
      ciphertext: base64Decode(map['ct'] as String),
    );
  }
}

class PinCrypto {
  const PinCrypto._();

  /// Iterazioni PBKDF2.
  ///
  /// Valore scelto come compromesso: abbastanza alto da rendere costoso un
  /// attacco a dizionario sui PIN, abbastanza basso da restare accettabile
  /// anche su Web, dove PBKDF2 gira in Dart puro e quindi più lentamente
  /// che in codice nativo.
  static const iterations = 150000;

  static const _keyLength = 32; // AES-256
  static const _saltLength = 16;
  static const _nonceLength = 12; // dimensione raccomandata per GCM
  static const _macBits = 128;

  /// Byte casuali dal generatore crittografico della piattaforma.
  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = random.nextInt(256);
    }
    return out;
  }

  /// Deriva la chiave di protezione dal PIN.
  static Uint8List deriveKek(String pin, Uint8List salt, int iterations) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, _keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(pin)));
  }

  /// Genera una nuova chiave dati e la incapsula con il PIN indicato.
  static ({WrappedKey wrapped, Uint8List dek}) createVault(String pin) {
    final dek = randomBytes(_keyLength);
    return (wrapped: wrapKey(dek, pin), dek: dek);
  }

  /// Incapsula una chiave dati esistente sotto un nuovo PIN.
  ///
  /// Usato al cambio PIN: la DEK resta la stessa, quindi il database non
  /// va ricifrato.
  static WrappedKey wrapKey(Uint8List dek, String pin) {
    final salt = randomBytes(_saltLength);
    final nonce = randomBytes(_nonceLength);
    final kek = deriveKek(pin, salt, iterations);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(kek), _macBits, nonce, Uint8List(0)));
    return WrappedKey(
      salt: salt,
      nonce: nonce,
      ciphertext: cipher.process(dek),
      iterations: iterations,
    );
  }

  /// Recupera la chiave dati dal PIN.
  ///
  /// Lancia [InvalidPinException] se il PIN è errato: non serve confrontare
  /// hash, è il tag di autenticazione GCM a non tornare.
  static Uint8List unwrapKey(WrappedKey wrapped, String pin) {
    final kek = deriveKek(pin, wrapped.salt, wrapped.iterations);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(kek), _macBits, wrapped.nonce, Uint8List(0)),
      );
    try {
      return cipher.process(wrapped.ciphertext);
    } on InvalidCipherTextException {
      throw const InvalidPinException();
    }
  }

  /// Rappresentazione esadecimale della chiave dati.
  ///
  /// Va usata con `PRAGMA hexkey`, che SQLite3 Multiple Ciphers interpreta
  /// come materiale di chiave grezzo: si evita così che il motore applichi
  /// una seconda derivazione a una chiave che è già casuale.
  ///
  /// Da non usare con `PRAGMA key = x'...'`: in quella posizione SQLite non
  /// accetta un letterale blob e solleva un errore di sintassi.
  static String toHexKey(Uint8List dek) =>
      dek.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
