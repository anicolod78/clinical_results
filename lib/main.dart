import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/appearance.dart';
import 'app/session.dart';
import 'app/theme.dart';
import 'features/lock/lock_screens.dart';
import 'features/patients/patients_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nomi di mesi e formati italiani: le date compaiono ovunque nell'app e
  // vanno lette a colpo d'occhio.
  await initializeDateFormatting('it_IT');
  runApp(const ProviderScope(child: ClinicalResultsApp()));
}

class ClinicalResultsApp extends ConsumerWidget {
  const ClinicalResultsApp({super.key});

  /// Serve a riportare l'utente alla schermata di blocco quando la sessione
  /// si chiude: le schermate aperte restano sopra la radice e coprirebbero
  /// la richiesta del codice.
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Risultati clinici',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Root(),
    );
  }
}

/// Sceglie la schermata in base allo stato della sessione e sorveglia il
/// ciclo di vita per il blocco automatico.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = ref.read(sessionProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        session.onPaused();
      case AppLifecycleState.resumed:
        session.onResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alla chiusura della sessione le schermate aperte vanno congedate.
    //
    // La radice torna alla richiesta del codice, ma le schermate spinte sopra
    // di essa restano al loro posto: l'utente si ritrovava davanti la scheda
    // di un paziente ormai priva di database, e doveva tornare indietro a
    // mano per poter reinserire il codice. Congedarle è anche corretto dal
    // punto di vista della riservatezza, perché quelle schermate mostrano
    // ancora dati sanitari.
    ref.listen(sessionProvider, (previous, next) {
      if (previous is SessionUnlocked && next is! SessionUnlocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ClinicalResultsApp.navigatorKey.currentState
              ?.popUntil((route) => route.isFirst);
        });
      }
    });

    final session = ref.watch(sessionProvider);

    return switch (session) {
      SessionLoading() => const _Splash(),
      SessionNeedsSetup(:final error, :final busy) =>
        PinSetupScreen(error: error, busy: busy),
      SessionLocked(
        :final error,
        :final busy,
        :final lockoutUntil,
        :final failedAttempts,
      ) =>
        UnlockScreen(
          error: error,
          busy: busy,
          lockoutUntil: lockoutUntil,
          failedAttempts: failedAttempts,
        ),
      SessionUnlocked() => const PatientsScreen(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
