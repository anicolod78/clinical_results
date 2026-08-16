import 'dart:typed_data';

import 'package:clinical_results/core/security/pin_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('protezione della chiave con il PIN', () {
    test('il PIN corretto restituisce la stessa chiave dati', () {
      final vault = PinCrypto.createVault('428913');
      final recovered = PinCrypto.unwrapKey(vault.wrapped, '428913');
      expect(recovered, vault.dek);
      expect(vault.dek, hasLength(32));
    });

    test('un PIN errato non apre la chiave', () {
      final vault = PinCrypto.createVault('428913');
      expect(
        () => PinCrypto.unwrapKey(vault.wrapped, '428914'),
        throwsA(isA<InvalidPinException>()),
      );
    });

    test('il PIN non compare nel dato salvato', () {
      const pin = '428913';
      final vault = PinCrypto.createVault(pin);
      final stored = vault.wrapped.toJson();
      expect(stored.contains(pin), isFalse);
      // Nemmeno la chiave dati deve essere ricavabile dal blob salvato.
      expect(stored.contains(PinCrypto.toHexKey(vault.dek)), isFalse);
    });

    test('due configurazioni con lo stesso PIN producono chiavi diverse', () {
      final a = PinCrypto.createVault('000000');
      final b = PinCrypto.createVault('000000');
      expect(a.dek, isNot(b.dek), reason: 'la chiave dati deve essere casuale');
      expect(a.wrapped.salt, isNot(b.wrapped.salt), reason: 'il sale deve essere casuale');
    });

    test('sopravvive alla serializzazione', () {
      final vault = PinCrypto.createVault('135790');
      final restored = WrappedKey.fromJson(vault.wrapped.toJson());
      expect(PinCrypto.unwrapKey(restored, '135790'), vault.dek);
    });

    test('cambiare PIN conserva la chiave dati', () {
      final vault = PinCrypto.createVault('111111');
      final rewrapped = PinCrypto.wrapKey(vault.dek, '999999');

      expect(PinCrypto.unwrapKey(rewrapped, '999999'), vault.dek,
          reason: 'il database non deve essere ricifrato al cambio PIN');
      expect(
        () => PinCrypto.unwrapKey(rewrapped, '111111'),
        throwsA(isA<InvalidPinException>()),
        reason: 'il vecchio PIN non deve più funzionare',
      );
    });

    test('produce una chiave esadecimale utilizzabile da PRAGMA hexkey', () {
      final dek = Uint8List.fromList(List.generate(32, (i) => i));
      final hex = PinCrypto.toHexKey(dek);
      expect(hex, hasLength(64), reason: '32 byte = 64 caratteri esadecimali');
      expect(hex, startsWith('000102030405'));
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(hex), isTrue);
    });

    test('la derivazione è abbastanza lenta da ostacolare la forza bruta', () {
      final sw = Stopwatch()..start();
      PinCrypto.deriveKek('428913', PinCrypto.randomBytes(16), PinCrypto.iterations);
      sw.stop();
      // Su un PIN a sei cifre la difesa principale è il costo della
      // derivazione: se scendesse sotto qualche decina di millisecondi
      // l'intero spazio dei PIN sarebbe percorribile troppo in fretta.
      expect(sw.elapsedMilliseconds, greaterThan(20),
          reason: 'derivazione troppo veloce: ${sw.elapsedMilliseconds} ms');
      // Il tempo misurato è un parametro di sicurezza: va reso visibile,
      // perché su una macchina molto più veloce andrebbe rialzato.
      // ignore: avoid_print
      print('PBKDF2 ${PinCrypto.iterations} iterazioni: ${sw.elapsedMilliseconds} ms');
    });
  });
}
