/// Archivio protetto per i segreti dell'applicazione.
///
/// Contiene la chiave dati incapsulata e i contatori antiforzatura. È dietro
/// un'interfaccia per due motivi: rendere verificabile con test la politica
/// dei tentativi, e poter sostituire l'implementazione senza toccare il resto.
///
/// Su Android il pacchetto sottostante appoggia il valore al Keystore di
/// sistema: la chiave incapsulata è quindi protetta anche da una seconda
/// barriera, legata al dispositivo, oltre che dal PIN.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([
    this._storage = const FlutterSecureStorage(
      // `resetOnError` è disattivato di proposito. Il valore predefinito
      // cancella il dato quando la decifratura fallisce, e qui il dato è la
      // sola chiave che apre l'archivio sanitario: un contrattempo del
      // Keystore distruggerebbe in silenzio tutto lo storico. Meglio un
      // errore visibile, che lascia margine per capire cosa è successo.
      aOptions: AndroidOptions(resetOnError: false),
    ),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// Implementazione in memoria, usata dai test.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  Map<String, String> get snapshot => Map.unmodifiable(_values);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}
