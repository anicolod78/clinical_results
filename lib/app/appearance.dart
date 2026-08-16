/// Scelta fra tema chiaro, scuro o quello di sistema.
///
/// La preferenza è conservata nell'archivio protetto e non nel database: il
/// tema serve già alla schermata di blocco, cioè prima che il database sia
/// apribile. Non è un segreto, ma è l'unico deposito disponibile in quel
/// momento, e evita di aggiungere una dipendenza solo per questo.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'settings.theme_mode';

  @override
  ThemeMode build() {
    unawaited(_restore());
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final stored = await ref.read(secureStoreProvider).read(_key);
    final restored = _decode(stored);
    if (restored != null) state = restored;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(secureStoreProvider).write(_key, mode.name);
  }

  static ThemeMode? _decode(String? raw) {
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Etichetta della modalità, per le impostazioni.
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Sistema',
  ThemeMode.light => 'Chiaro',
  ThemeMode.dark => 'Scuro',
};

IconData themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.brightness_auto_outlined,
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
};
