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
    required this.unknown,
  });

  final Color high;
  final Color low;
  final Color normal;
  final Color unknown;

  Color of(ValueFlag flag) => switch (flag) {
    ValueFlag.high => high,
    ValueFlag.low => low,
    ValueFlag.normal => normal,
    ValueFlag.unknown => unknown,
  };

  static const light = FlagPalette(
    high: Color(0xFFB3261E),
    low: Color(0xFF00629E),
    normal: Color(0xFF1B6E3C),
    unknown: Color(0xFF5F6368),
  );

  static const dark = FlagPalette(
    high: Color(0xFFFFB4AB),
    low: Color(0xFF8ECDFF),
    normal: Color(0xFF7EDBA0),
    unknown: Color(0xFFBFC5CB),
  );
}

/// Simbolo che accompagna il colore.
IconData? flagIcon(ValueFlag flag) => switch (flag) {
  ValueFlag.high => Icons.arrow_upward,
  ValueFlag.low => Icons.arrow_downward,
  ValueFlag.normal => null,
  ValueFlag.unknown => null,
};

String flagLabel(ValueFlag flag) => switch (flag) {
  ValueFlag.high => 'sopra il riferimento',
  ValueFlag.low => 'sotto il riferimento',
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
