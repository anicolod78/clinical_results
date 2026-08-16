import 'dart:typed_data';

import 'package:clinical_results/core/security/pin_crypto.dart';
import 'package:clinical_results/core/security/pin_policy.dart';
import 'package:clinical_results/core/security/secure_store.dart';
import 'package:clinical_results/core/security/vault.dart';
import 'package:flutter_test/flutter_test.dart';

/// Involucro finto: verifica la logica del vault senza pagare ogni volta il
/// costo di PBKDF2, che è misurato a parte in pin_crypto_test.dart.
Future<String> fakeWrap(Uint8List dek, String pin) async => 'wrapped:$pin';

Future<Uint8List> fakeUnwrap(String wrapped, String pin) async {
  if (wrapped != 'wrapped:$pin') throw const InvalidPinException();
  return Uint8List.fromList(List.filled(32, 7));
}

/// Crittografia reale, ma sincrona: `compute` richiederebbe un isolate.
Future<String> realWrap(Uint8List dek, String pin) async =>
    PinCrypto.wrapKey(dek, pin).toJson();

Future<Uint8List> realUnwrap(String wrapped, String pin) async =>
    PinCrypto.unwrapKey(WrappedKey.fromJson(wrapped), pin);

void main() {
  late InMemorySecureStore store;
  late DateTime clock;

  VaultService buildVault({bool realCrypto = false}) => VaultService(
    store: store,
    now: () => clock,
    wrapRunner: realCrypto ? realWrap : fakeWrap,
    unwrapRunner: realCrypto ? realUnwrap : fakeUnwrap,
  );

  setUp(() {
    store = InMemorySecureStore();
    clock = DateTime(2026, 8, 14, 10, 0, 0);
  });

  group('configurazione', () {
    test('parte non configurato e passa a bloccato dopo il setup', () async {
      final vault = buildVault();
      expect(await vault.status(), VaultStatus.notConfigured);

      await vault.setup('428913');
      expect(await vault.status(), VaultStatus.locked);
      expect(await vault.isConfigured, isTrue);
    });

    test('non sovrascrive una configurazione esistente', () async {
      final vault = buildVault();
      await vault.setup('428913');
      expect(() => vault.setup('999888'), throwsStateError,
          reason: 'sovrascrivere la chiave renderebbe illeggibile lo storico');
    });

    test('sbloccare senza configurazione è un errore distinto', () async {
      final vault = buildVault();
      expect(
        () => vault.unlock('428913'),
        throwsA(isA<VaultNotConfiguredException>()),
      );
    });

    test('il PIN non finisce nell archivio protetto', () async {
      final vault = buildVault(realCrypto: true);
      await vault.setup('428913');
      final dump = store.snapshot.values.join('|');
      expect(dump.contains('428913'), isFalse);
    });
  });

  group('sblocco', () {
    test('il PIN corretto restituisce sempre la stessa chiave', () async {
      final vault = buildVault(realCrypto: true);
      final created = await vault.setup('428913');
      final unlocked = await vault.unlock('428913');
      expect(unlocked, created);
    });

    test('il PIN errato non restituisce nulla', () async {
      final vault = buildVault();
      await vault.setup('428913');
      expect(
        () => vault.unlock('428914'),
        throwsA(isA<InvalidPinException>()),
      );
    });

    test('uno sblocco riuscito azzera i tentativi', () async {
      final vault = buildVault();
      await vault.setup('428913');

      for (var i = 0; i < 3; i++) {
        await expectLater(
          vault.unlock('000001'),
          throwsA(isA<InvalidPinException>()),
        );
      }
      expect(await vault.failedAttempts(), 3);

      await vault.unlock('428913');
      expect(await vault.failedAttempts(), 0);
      expect(await vault.lockoutRemaining(), isNull);
    });
  });

  group('difesa dai tentativi ripetuti', () {
    test('i primi errori non impongono attesa', () {
      for (var i = 1; i <= VaultService.freeAttempts; i++) {
        expect(VaultService.delayAfter(i), Duration.zero,
            reason: 'un errore di battitura non deve bloccare l utente');
      }
    });

    test('oltre la soglia l attesa raddoppia a ogni errore', () {
      expect(VaultService.delayAfter(5), const Duration(seconds: 30));
      expect(VaultService.delayAfter(6), const Duration(seconds: 60));
      expect(VaultService.delayAfter(7), const Duration(seconds: 120));
      expect(VaultService.delayAfter(8), const Duration(seconds: 240));
    });

    test('l attesa non supera il tetto massimo', () {
      expect(VaultService.delayAfter(50), VaultService.maxDelay);
    });

    test('durante l attesa il tentativo è respinto senza calcolare nulla',
        () async {
      final vault = buildVault();
      await vault.setup('428913');

      for (var i = 0; i < 5; i++) {
        await expectLater(
          vault.unlock('000001'),
          throwsA(isA<InvalidPinException>()),
        );
      }

      // Anche il PIN giusto deve attendere: altrimenti l attesa si potrebbe
      // aggirare provando codici a caso finché non si indovina.
      await expectLater(
        vault.unlock('428913'),
        throwsA(isA<VaultLockedException>()),
      );
    });

    test('l attesa resiste al riavvio dell applicazione', () async {
      var vault = buildVault();
      await vault.setup('428913');
      for (var i = 0; i < 5; i++) {
        await expectLater(
          vault.unlock('000001'),
          throwsA(isA<InvalidPinException>()),
        );
      }

      // Nuova istanza sullo stesso archivio: simula la chiusura dell app.
      vault = buildVault();
      expect(await vault.lockoutRemaining(), isNotNull);
      await expectLater(
        vault.unlock('428913'),
        throwsA(isA<VaultLockedException>()),
      );
    });

    test('trascorsa l attesa lo sblocco torna possibile', () async {
      final vault = buildVault();
      await vault.setup('428913');
      for (var i = 0; i < 5; i++) {
        await expectLater(
          vault.unlock('000001'),
          throwsA(isA<InvalidPinException>()),
        );
      }

      clock = clock.add(const Duration(seconds: 31));
      expect(await vault.lockoutRemaining(), isNull);
      expect(await vault.unlock('428913'), hasLength(32));
    });
  });

  group('cancellazione dopo troppi errori', () {
    test('è disattivata se non richiesta esplicitamente', () async {
      final vault = buildVault();
      await vault.setup('428913');
      expect(await vault.wipeAfterAttempts(), isNull,
          reason: 'distruggere lo storico non può essere il comportamento '
              'predefinito');
    });

    test('quando attiva cancella la chiave al limite indicato', () async {
      final vault = buildVault();
      await vault.setup('428913');
      await vault.setWipeAfterAttempts(3);

      for (var i = 0; i < 3; i++) {
        await expectLater(
          vault.unlock('000001'),
          throwsA(isA<InvalidPinException>()),
        );
        clock = clock.add(const Duration(hours: 2));
      }

      expect(await vault.isConfigured, isFalse);
      expect(
        () => vault.unlock('428913'),
        throwsA(isA<VaultNotConfiguredException>()),
        reason: 'senza chiave il database non è più apribile',
      );
    });
  });

  group('cambio del PIN', () {
    test('conserva la chiave dati, quindi i dati esistenti', () async {
      final vault = buildVault(realCrypto: true);
      final original = await vault.setup('428913');

      await vault.changePin('428913', '777555');

      expect(await vault.unlock('777555'), original,
          reason: 'il database non deve essere ricifrato');
      expect(
        () => vault.unlock('428913'),
        throwsA(isA<InvalidPinException>()),
      );
    });

    test('richiede il PIN attuale corretto', () async {
      final vault = buildVault(realCrypto: true);
      await vault.setup('428913');
      expect(
        () => vault.changePin('000000', '777555'),
        throwsA(isA<InvalidPinException>()),
      );
    });
  });

  group('criterio del codice', () {
    test('accetta un codice ragionevole', () {
      expect(PinPolicy.validate('428913'), isNull);
      expect(PinPolicy.validate('90271633'), isNull);
    });

    test('rifiuta codici troppo corti o non numerici', () {
      expect(PinPolicy.validate('1234'), isNotNull);
      expect(PinPolicy.validate('12ab56'), isNotNull);
      expect(PinPolicy.validate(''), isNotNull);
    });

    test('rifiuta le combinazioni che si provano per prime', () {
      expect(PinPolicy.validate('111111'), isNotNull);
      expect(PinPolicy.validate('123456'), isNotNull);
      expect(PinPolicy.validate('654321'), isNotNull);
      expect(PinPolicy.validate('890123'), isNotNull);
      expect(PinPolicy.validate('123123'), isNotNull);
      expect(PinPolicy.validate('121212'), isNotNull);
    });
  });
}
