/// Stato della sessione: configurazione del codice, blocco e sblocco.
///
/// Il database esiste solo mentre la sessione è sbloccata. Bloccando l'app la
/// connessione viene chiusa e il riferimento eliminato: senza la chiave in
/// memoria i dati tornano illeggibili anche per l'applicazione stessa.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../core/security/pin_crypto.dart';
import '../core/security/pin_policy.dart';
import '../core/security/secure_store.dart';
import '../core/security/vault.dart';

sealed class SessionState {
  const SessionState();
}

/// Verifica iniziale dell'archivio protetto.
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Primo avvio: va scelto il codice di sicurezza.
class SessionNeedsSetup extends SessionState {
  const SessionNeedsSetup({this.error, this.busy = false});

  final String? error;
  final bool busy;
}

/// Archivio configurato ma chiuso.
class SessionLocked extends SessionState {
  const SessionLocked({
    this.error,
    this.busy = false,
    this.lockoutUntil,
    this.failedAttempts = 0,
  });

  final String? error;
  final bool busy;

  /// Momento fino al quale i tentativi sono sospesi.
  final DateTime? lockoutUntil;

  final int failedAttempts;
}

/// Sessione aperta: il database è utilizzabile.
class SessionUnlocked extends SessionState {
  const SessionUnlocked(this.database);

  final AppDatabase database;
}

class SessionController extends Notifier<SessionState> {
  Timer? _autoLockTimer;

  /// Attesa prima del blocco automatico quando l'app va in secondo piano.
  ///
  /// Non è immediato perché aprire la fotocamera o il selettore di file porta
  /// l'app in secondo piano: bloccare subito costringerebbe a reinserire il
  /// codice nel bel mezzo di un'importazione.
  ///
  /// I 45 secondi iniziali si sono rivelati troppo pochi anche solo per
  /// consultare un'altra applicazione e tornare indietro. Tre minuti coprono
  /// quel caso restando ben sotto la soglia oltre la quale un telefono lasciato
  /// incustodito diventa un problema: chi si allontana davvero blocca lo
  /// schermo, e allora il blocco scatta comunque.
  static const autoLockDelay = Duration(minutes: 3);

  @override
  SessionState build() {
    ref.onDispose(() {
      _autoLockTimer?.cancel();
      final current = state;
      if (current is SessionUnlocked) unawaited(current.database.close());
    });
    unawaited(_restore());
    return const SessionLoading();
  }

  VaultService get _vault => ref.read(vaultProvider);

  Future<void> _restore() async {
    final configured = await _vault.isConfigured;
    if (!configured) {
      state = const SessionNeedsSetup();
      return;
    }
    state = SessionLocked(
      failedAttempts: await _vault.failedAttempts(),
      lockoutUntil: await _lockoutUntil(),
    );
  }

  Future<DateTime?> _lockoutUntil() async {
    final remaining = await _vault.lockoutRemaining();
    return remaining == null ? null : DateTime.now().add(remaining);
  }

  /// Configura il codice di sicurezza al primo avvio.
  Future<void> setupPin(String pin, String confirmation) async {
    final policyError = PinPolicy.validate(pin);
    if (policyError != null) {
      state = SessionNeedsSetup(error: policyError);
      return;
    }
    if (pin != confirmation) {
      state = const SessionNeedsSetup(error: 'I due codici non coincidono.');
      return;
    }

    state = const SessionNeedsSetup(busy: true);
    try {
      final dek = await _vault.setup(pin);
      await _openDatabase(dek);
    } catch (e) {
      state = SessionNeedsSetup(error: 'Configurazione non riuscita: $e');
    }
  }

  /// Verifica il codice e apre il database.
  Future<void> unlock(String pin) async {
    state = SessionLocked(
      busy: true,
      failedAttempts: await _vault.failedAttempts(),
    );
    try {
      final dek = await _vault.unlock(pin);
      await _openDatabase(dek);
    } on InvalidPinException {
      final attempts = await _vault.failedAttempts();
      final until = await _lockoutUntil();
      state = SessionLocked(
        error: until != null
            ? 'Codice errato. Troppi tentativi: attendere.'
            : 'Codice errato.',
        failedAttempts: attempts,
        lockoutUntil: until,
      );
    } on VaultLockedException catch (e) {
      state = SessionLocked(
        error: 'Troppi tentativi: attendere ${_describe(e.remaining)}.',
        failedAttempts: await _vault.failedAttempts(),
        lockoutUntil: DateTime.now().add(e.remaining),
      );
    } on VaultNotConfiguredException {
      // La cancellazione automatica ha rimosso la chiave.
      state = const SessionNeedsSetup(
        error: 'Archivio azzerato dopo troppi tentativi errati.',
      );
    } catch (e) {
      state = SessionLocked(error: 'Apertura non riuscita: $e');
    }
  }

  Future<void> _openDatabase(Uint8List dek) async {
    final open = ref.read(databaseOpenerProvider);
    final database = await open(PinCrypto.toHexKey(dek));
    state = SessionUnlocked(database);
  }

  /// Chiude la sessione e la connessione al database.
  Future<void> lock() async {
    _autoLockTimer?.cancel();
    final current = state;
    if (current is SessionUnlocked) {
      await current.database.close();
    }
    state = SessionLocked(failedAttempts: await _vault.failedAttempts());
  }

  /// L'app è passata in secondo piano: avvia il conto alla rovescia.
  void onPaused() {
    if (state is! SessionUnlocked) return;
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(autoLockDelay, () => unawaited(lock()));
  }

  /// L'app è tornata in primo piano entro il tempo consentito.
  void onResumed() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  /// Cambia il codice mantenendo i dati.
  Future<String?> changePin(String currentPin, String newPin) async {
    final policyError = PinPolicy.validate(newPin);
    if (policyError != null) return policyError;
    try {
      await _vault.changePin(currentPin, newPin);
      return null;
    } on InvalidPinException {
      return 'Il codice attuale non è corretto.';
    } on VaultLockedException catch (e) {
      return 'Troppi tentativi: attendere ${_describe(e.remaining)}.';
    }
  }

  /// Cancella chiave e archivio: operazione irreversibile.
  Future<void> destroyEverything() async {
    final current = state;
    if (current is SessionUnlocked) {
      await current.database.close();
    }
    await AppDatabase.destroy();
    await _vault.wipe();
    state = const SessionNeedsSetup();
  }

  static String _describe(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds} secondi';
    if (d.inHours < 1) return '${d.inMinutes} minuti';
    return '${d.inHours} ore';
  }
}

/// Archivio protetto del dispositivo. I test lo sostituiscono con la
/// versione in memoria.
final secureStoreProvider = Provider<SecureStore>(
  (ref) => const FlutterSecureStore(),
);

/// Apertura del database a partire dalla chiave dati.
typedef DatabaseOpener = Future<AppDatabase> Function(String hexKey);

/// Reso sostituibile perché l'apertura reale dipende dal percorso di
/// archiviazione della piattaforma: i test la rimpiazzano con un database
/// in memoria e possono così esercitare le schermate vere.
final databaseOpenerProvider = Provider<DatabaseOpener>(
  (ref) => AppDatabase.open,
);

final vaultProvider = Provider<VaultService>(
  (ref) => VaultService(store: ref.watch(secureStoreProvider)),
);

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
