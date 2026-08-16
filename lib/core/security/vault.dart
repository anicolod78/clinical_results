/// Custodia della chiave dati e difesa dai tentativi ripetuti.
///
/// Il PIN non viene mai confrontato con un valore memorizzato: si prova a
/// scartare la chiave dati e, se il PIN è sbagliato, l'autenticazione GCM
/// fallisce. Non esiste quindi alcun verificatore da estrarre dal dispositivo.
///
/// Sopra questa base c'è la difesa contro chi tenta i PIN a raffica. Un codice
/// a sei cifre si esaurisce in fretta se lo si può provare senza limiti: dopo
/// alcuni errori l'attesa cresce in modo esponenziale, e l'attesa è registrata
/// nell'archivio protetto, così chiudere e riaprire l'app non la azzera.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'pin_crypto.dart';
import 'secure_store.dart';

/// Sollevata quando i tentativi sono temporaneamente sospesi.
class VaultLockedException implements Exception {
  const VaultLockedException(this.remaining);

  final Duration remaining;

  @override
  String toString() =>
      'VaultLockedException: riprovare fra ${remaining.inSeconds} s';
}

/// Sollevata quando si tenta di sbloccare un archivio mai configurato.
class VaultNotConfiguredException implements Exception {
  const VaultNotConfiguredException();
}

/// Stato dell'archivio protetto.
enum VaultStatus { notConfigured, locked, unlocked }

/// Esegue la derivazione fuori dal thread della UI.
///
/// PBKDF2 con 150.000 iterazioni impegna il processore per quasi un secondo:
/// eseguirlo sul thread principale bloccherebbe l'interfaccia durante lo
/// sblocco. Su Web gli isolate non esistono e il calcolo resta sul thread
/// principale: è accettabile perché quella piattaforma serve per le prove.
Future<Uint8List> _defaultUnwrap(String wrappedJson, String pin) {
  return compute(_unwrapTask, [wrappedJson, pin]);
}

Uint8List _unwrapTask(List<String> args) =>
    PinCrypto.unwrapKey(WrappedKey.fromJson(args[0]), args[1]);

Future<String> _defaultWrap(Uint8List dek, String pin) {
  return compute(_wrapTask, (dek, pin));
}

String _wrapTask((Uint8List, String) args) =>
    PinCrypto.wrapKey(args.$1, args.$2).toJson();

typedef UnwrapRunner = Future<Uint8List> Function(String wrappedJson, String pin);
typedef WrapRunner = Future<String> Function(Uint8List dek, String pin);

class VaultService {
  VaultService({
    required SecureStore store,
    DateTime Function()? now,
    UnwrapRunner? unwrapRunner,
    WrapRunner? wrapRunner,
  }) : _store = store,
       _now = now ?? DateTime.now,
       _unwrap = unwrapRunner ?? _defaultUnwrap,
       _wrap = wrapRunner ?? _defaultWrap;

  final SecureStore _store;
  final DateTime Function() _now;
  final UnwrapRunner _unwrap;
  final WrapRunner _wrap;

  static const _kWrapped = 'vault.wrapped';
  static const _kFailed = 'vault.failed_attempts';
  static const _kLockedUntil = 'vault.locked_until';
  static const _kWipeAfter = 'vault.wipe_after';

  /// Tentativi concessi senza penalità, per non punire l'errore di battitura.
  static const freeAttempts = 4;

  /// Attesa massima fra un tentativo e il successivo.
  static const maxDelay = Duration(hours: 1);

  Future<bool> get isConfigured async => await _store.read(_kWrapped) != null;

  Future<VaultStatus> status() async =>
      await isConfigured ? VaultStatus.locked : VaultStatus.notConfigured;

  /// Numero di tentativi errati consecutivi.
  Future<int> failedAttempts() async =>
      int.tryParse(await _store.read(_kFailed) ?? '') ?? 0;

  /// Tempo che manca prima di poter riprovare, `null` se non c'è attesa.
  Future<Duration?> lockoutRemaining() async {
    final raw = await _store.read(_kLockedUntil);
    if (raw == null) return null;
    final until = DateTime.tryParse(raw);
    if (until == null) return null;
    final remaining = until.difference(_now());
    return remaining.isNegative ? null : remaining;
  }

  /// Dopo quanti tentativi errati l'archivio viene cancellato.
  ///
  /// `null` disabilita la cancellazione, ed è l'impostazione predefinita:
  /// distruggere lo storico sanitario di una persona per una serie di errori
  /// è un danno serio, quindi deve essere una scelta esplicita.
  Future<int?> wipeAfterAttempts() async =>
      int.tryParse(await _store.read(_kWipeAfter) ?? '');

  Future<void> setWipeAfterAttempts(int? attempts) async {
    if (attempts == null) {
      await _store.delete(_kWipeAfter);
    } else {
      await _store.write(_kWipeAfter, '$attempts');
    }
  }

  /// Configura il codice di sicurezza e restituisce la chiave dati.
  ///
  /// Rifiuta di sovrascrivere una configurazione esistente: per cambiare PIN
  /// serve [changePin], che conserva la chiave e quindi i dati.
  Future<Uint8List> setup(String pin) async {
    if (await isConfigured) {
      throw StateError('Archivio già configurato: usare changePin.');
    }
    final dek = PinCrypto.randomBytes(32);
    await _store.write(_kWrapped, await _wrap(dek, pin));
    await _resetAttempts();
    return dek;
  }

  /// Verifica il PIN e restituisce la chiave dati.
  Future<Uint8List> unlock(String pin) async {
    final wrapped = await _store.read(_kWrapped);
    if (wrapped == null) throw const VaultNotConfiguredException();

    final waiting = await lockoutRemaining();
    if (waiting != null) throw VaultLockedException(waiting);

    try {
      final dek = await _unwrap(wrapped, pin);
      await _resetAttempts();
      return dek;
    } on InvalidPinException {
      await _registerFailure();
      rethrow;
    }
  }

  /// Sostituisce il PIN mantenendo la stessa chiave dati.
  ///
  /// Il database non viene ricifrato: cambia solo l'involucro della chiave.
  Future<void> changePin(String currentPin, String newPin) async {
    final dek = await unlock(currentPin);
    await _store.write(_kWrapped, await _wrap(dek, newPin));
    await _resetAttempts();
  }

  /// Cancella la chiave. Senza di essa il database resta illeggibile.
  Future<void> wipe() async {
    await _store.delete(_kWrapped);
    await _resetAttempts();
    await _store.delete(_kWipeAfter);
  }

  Future<void> _resetAttempts() async {
    await _store.delete(_kFailed);
    await _store.delete(_kLockedUntil);
  }

  Future<void> _registerFailure() async {
    final failed = await failedAttempts() + 1;
    await _store.write(_kFailed, '$failed');

    final limit = await wipeAfterAttempts();
    if (limit != null && failed >= limit) {
      await wipe();
      return;
    }

    final delay = delayAfter(failed);
    if (delay > Duration.zero) {
      await _store.write(_kLockedUntil, _now().add(delay).toIso8601String());
    }
  }

  /// Attesa imposta dopo [failed] tentativi errati consecutivi.
  ///
  /// Raddoppia a ogni errore oltre la soglia di tolleranza: pochi errori
  /// costano poco, un tentativo sistematico diventa in fretta impraticabile.
  static Duration delayAfter(int failed) {
    if (failed <= freeAttempts) return Duration.zero;
    final step = failed - freeAttempts;
    final seconds = 15 * math.pow(2, step).toInt();
    return seconds >= maxDelay.inSeconds ? maxDelay : Duration(seconds: seconds);
  }
}
