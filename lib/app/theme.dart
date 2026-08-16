/// Aspetto dell'applicazione.
library;

import 'package:flutter/material.dart';

import '../features/parsing/models.dart';

/// Colori usati per segnalare la posizione di un valore rispetto alla soglia.
///
/// Non si affidano al solo colore: nella tabella e nei grafici ogni stato è
/// accompagnato da un simbolo (freccia su, freccia giù), perché la
/// distinzione rosso/verde è invisibile a una parte non trascurabile delle
/// persone, e qui indica un'informazione clinica.
class FlagPalette {
  const FlagPalette({
    required this.high,
    required this.low,
    required this.normal,
    required this.target,
    required this.unknown,
  });

  final Color high;
  final Color low;
  final Color normal;

  /// Obiettivo terapeutico mancato: distinto dal fuori intervallo, perché
  /// mostrarli con lo stesso rosso direbbe una cosa clinicamente diversa.
  final Color target;

  final Color unknown;

  Color of(ValueFlag flag) => switch (flag) {
    ValueFlag.high => high,
    ValueFlag.low => low,
    ValueFlag.normal => normal,
    ValueFlag.aboveTarget || ValueFlag.belowTarget => target,
    ValueFlag.unknown => unknown,
  };

  static const light = FlagPalette(
    high: Color(0xFFB3261E),
    low: Color(0xFF00629E),
    normal: Color(0xFF1B6E3C),
    target: Color(0xFF8A5000),
    unknown: Color(0xFF5F6368),
  );

  static const dark = FlagPalette(
    high: Color(0xFFFFB4AB),
    low: Color(0xFF8ECDFF),
    normal: Color(0xFF7EDBA0),
    target: Color(0xFFFFB77C),
    unknown: Color(0xFFBFC5CB),
  );
}

/// Simbolo che accompagna il colore.
///
/// La freccia piena segnala il fuori intervallo, il gallone l'obiettivo
/// mancato: la differenza resta leggibile anche senza distinguere i colori.
IconData? flagIcon(ValueFlag flag) => switch (flag) {
  ValueFlag.high => Icons.arrow_upward,
  ValueFlag.low => Icons.arrow_downward,
  ValueFlag.aboveTarget => Icons.keyboard_arrow_up,
  ValueFlag.belowTarget => Icons.keyboard_arrow_down,
  ValueFlag.normal => null,
  ValueFlag.unknown => null,
};

String flagLabel(ValueFlag flag) => switch (flag) {
  ValueFlag.high => 'sopra il riferimento',
  ValueFlag.low => 'sotto il riferimento',
  ValueFlag.aboveTarget => 'oltre il valore desiderabile',
  ValueFlag.belowTarget => 'sotto il valore desiderabile',
  ValueFlag.normal => 'nel riferimento',
  ValueFlag.unknown => 'senza riferimento',
};

class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF2E6B8A);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      ),
    );
  }

  /// Tavolozza dei segnali adatta al tema in uso.
  static FlagPalette paletteOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? FlagPalette.dark
      : FlagPalette.light;
}
