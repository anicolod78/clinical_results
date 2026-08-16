import 'package:clinical_results/app/session.dart';
import 'package:clinical_results/core/db/database.dart';
import 'package:clinical_results/core/security/pin_crypto.dart';
import 'package:clinical_results/core/security/secure_store.dart';
import 'package:clinical_results/core/security/vault.dart';
import 'package:clinical_results/features/lock/lock_screens.dart';
import 'package:clinical_results/features/patients/patients_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:clinical_results/main.dart';

/// Percorso dell'utente attraverso le schermate reali.
///
/// L'archivio protetto è in memoria e il database è aperto in memoria, ma le
/// schermate, il controllore di sessione e la crittografia sono quelli veri.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('it_IT'));

  late InMemorySecureStore store;
  final databases = <AppDatabase>[];

  setUp(() {
    store = InMemorySecureStore();
    databases.clear();
  });

  // I database non vengono chiusi qui: se ne occupa già `SessionController`
  // quando l'ambito dei provider viene smontato. Chiuderli una seconda volta
  // farebbe terminare i flussi di drift dopo l'ultimo frame, lasciando timer
  // in sospeso che il framework di test segnala come errore.

  /// Crittografia reale ma sincrona: `compute` avvierebbe un isolate per ogni
  /// derivazione, rendendo i test lenti senza aggiungere nulla.
  VaultService buildVault() => VaultService(
    store: store,
    wrapRunner: (dek, pin) async => PinCrypto.wrapKey(dek, pin).toJson(),
    unwrapRunner: (wrapped, pin) async =>
        PinCrypto.unwrapKey(WrappedKey.fromJson(wrapped), pin),
  );

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        secureStoreProvider.overrideWithValue(store),
        vaultProvider.overrideWith((ref) => buildVault()),
        databaseOpenerProvider.overrideWithValue((hexKey) async {
          final db = AppDatabase(NativeDatabase.memory());
          databases.add(db);
          return db;
        }),
      ],
      child: const ClinicalResultsApp(),
    );
  }

  /// Fa avanzare l'interfaccia per un tempo limitato.
  ///
  /// Non si usa `pumpAndSettle`: le schermate di attesa contengono un
  /// indicatore di caricamento, che è un'animazione senza fine, e il test
  /// resterebbe bloccato in attesa di una quiete che non arriva mai.
  Future<void> settle(WidgetTester tester, {int frames = 20}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
  }

  /// Chiude l'applicazione lasciando scattare le pulizie differite.
  ///
  /// Va chiamata **dentro** il corpo del test, non da `addTearDown`. Quando lo
  /// smontaggio dell'ambito dei provider chiude i flussi di drift, drift
  /// programma un timer immediato per liberarli; flutter_test smonta l'albero
  /// al termine del corpo e verifica i timer pendenti subito dopo, prima che i
  /// tearDown registrati abbiano modo di eseguire. L'unico momento utile per
  /// concedere quel frame è quindi prima che il corpo termini.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.widgetWithText(OutlinedButton, digit).first);
      await tester.pump();
    }
  }

  /// Configurazione iniziale del codice, punto di partenza di molti percorsi.
  Future<void> completeSetup(WidgetTester tester, String pin) async {
    await typePin(tester, pin);
    await tester.tap(find.widgetWithText(FilledButton, 'Avanti'));
    await settle(tester);
    await typePin(tester, pin);
    await tester.tap(find.widgetWithText(FilledButton, 'Conferma'));
    await settle(tester);
  }

  testWidgets('primo avvio: chiede di impostare il codice', (tester) async {
    await pumpApp(tester);

    expect(find.byType(PinSetupScreen), findsOneWidget);
    expect(find.text('Scegli un codice'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('rifiuta un codice troppo prevedibile', (tester) async {
    await pumpApp(tester);

    await typePin(tester, '123456');
    await tester.pump();

    expect(find.textContaining('sequenza'), findsOneWidget);
    // Il pulsante di conferma resta disattivato finché il codice è banale.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Avanti'),
    );
    expect(button.onPressed, isNull);
    await closeApp(tester);
  });

  testWidgets('configura il codice e apre l archivio', (tester) async {
    await pumpApp(tester);

    await typePin(tester, '428913');
    await tester.tap(find.widgetWithText(FilledButton, 'Avanti'));
    await settle(tester);

    expect(find.text('Ripeti il codice'), findsOneWidget);

    await typePin(tester, '428913');
    await tester.tap(find.widgetWithText(FilledButton, 'Conferma'));
    await settle(tester);

    expect(find.byType(PatientsScreen), findsOneWidget);
    expect(find.text('Nessun paziente'), findsOneWidget);
    expect(databases, hasLength(1), reason: 'il database deve essere aperto');
    await closeApp(tester);
  });

  testWidgets('i due codici devono coincidere', (tester) async {
    await pumpApp(tester);

    await typePin(tester, '428913');
    await tester.tap(find.widgetWithText(FilledButton, 'Avanti'));
    await settle(tester);

    await typePin(tester, '428914');
    await tester.tap(find.widgetWithText(FilledButton, 'Conferma'));
    await settle(tester);

    expect(find.textContaining('non coincidono'), findsOneWidget);
    expect(find.byType(PatientsScreen), findsNothing);
    await closeApp(tester);
  });

  testWidgets('al riavvio chiede il codice e non lo aggira', (tester) async {
    // Primo avvio: configurazione.
    await pumpApp(tester);
    await completeSetup(tester, '428913');
    expect(find.byType(PatientsScreen), findsOneWidget);

    // Riavvio dell'applicazione sullo stesso archivio protetto.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 20));
    await pumpApp(tester);

    expect(find.byType(UnlockScreen), findsOneWidget,
        reason: 'i dati sanitari non devono essere accessibili senza codice');

    // Codice errato: nessun accesso.
    await typePin(tester, '000111');
    await tester.tap(find.widgetWithText(FilledButton, 'Sblocca'));
    await settle(tester);
    expect(find.byType(PatientsScreen), findsNothing);
    expect(find.textContaining('errato'), findsOneWidget);

    // Codice corretto: accesso consentito.
    await typePin(tester, '428913');
    await tester.tap(find.widgetWithText(FilledButton, 'Sblocca'));
    await settle(tester);
    expect(find.byType(PatientsScreen), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('il comando di blocco chiude la sessione', (tester) async {
    await pumpApp(tester);
    await completeSetup(tester, '428913');

    await tester.tap(find.byTooltip('Blocca'));
    await settle(tester);

    expect(find.byType(UnlockScreen), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('crea un paziente e lo mostra in elenco', (tester) async {
    await pumpApp(tester);
    await completeSetup(tester, '428913');

    await tester.tap(find.text('Nuovo paziente'));
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome e cognome'),
      'Mario Rossi',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crea paziente'));
    await settle(tester);

    expect(find.text('Mario Rossi'), findsOneWidget);

    await closeApp(tester);
  });
}
