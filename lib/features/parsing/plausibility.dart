/// Riconoscimento dei valori implausibili prima che entrino in archivio.
///
/// Nasce da un errore reale: un ematocrito registrato come `472 %` con
/// riferimento `40 - 52`, cioè `47,2` letto senza la virgola. Il valore era
/// passato indenne dalla revisione, e mesi dopo nessuno avrebbe più potuto
/// riconoscerlo come sbagliato guardando lo storico — sarebbe rimasto un picco
/// inspiegabile che schiaccia la scala di tutto il grafico.
///
/// **Il criterio non è la distanza dall'intervallo.** Questa è la scelta di
/// fondo, ed è controintuitiva: PCR, ferritina, D-dimero e transaminasi
/// superano abitualmente il limite superiore di dieci o cinquanta volte con
/// valori veri, in sepsi, sovraccarico marziale ed epatite. Un avviso tarato
/// sulla distanza suonerebbe proprio sui referti più gravi, e chi lo vede
/// gridare al lupo ogni volta smette di leggerlo — restando poi indifeso
/// davvero, il giorno in cui l'errore c'è.
///
/// Si riconosce quindi la *forma dell'errore di acquisizione*, non l'anomalia
/// clinica. Tre regole, tutte ad alta precisione: nel dubbio, silenzio.
library;

import 'analyte_catalog.dart';
import 'models.dart';

/// Motivo per cui un valore risulta implausibile.
enum ImplausibilityKind {
  /// Rientrerebbe nell'intervallo spostando la virgola di una cifra.
  decimalShift,

  /// Percentuale oltre il 100 % dove il riferimento resta sotto.
  impossiblePercentage,

  /// Valore negativo dove il riferimento non ammette segno.
  negative,
}

/// Segnalazione su un singolo valore, con l'eventuale correzione proposta.
class ImplausibleValue {
  const ImplausibleValue({
    required this.kind,
    required this.message,
    this.suggested,
  });

  final ImplausibilityKind kind;

  /// Spiegazione rivolta a chi rivede il referto.
  final String message;

  /// Valore proposto in sostituzione, quando la regola sa indicarne uno.
  final double? suggested;

  @override
  String toString() => 'ImplausibleValue(${kind.name}, suggerito: $suggested)';
}

class Plausibility {
  const Plausibility._();

  /// Quanto dell'intervallo si esclude a ciascun estremo prima di accettare
  /// che uno spostamento di virgola "rientri".
  ///
  /// Senza questo margine la regola colpirebbe valori veri: leucociti 100 in
  /// una leucemia diventano 10,0 che è esattamente il limite superiore, e
  /// piastrine 1500 in una trombocitosi diventano 150 che è esattamente quello
  /// inferiore. Un errore di virgola atterra quasi sempre in mezzo
  /// all'intervallo, non appoggiato a un estremo.
  static const _coreMargin = 0.1;

  /// Esamina un valore e restituisce `null` se non c'è nulla da segnalare.
  ///
  /// [rawName] serve a consultare il catalogo: la stessa cifra è impossibile
  /// per il sodio e normale per la ferritina.
  static ImplausibleValue? check({
    required String rawName,
    required double? value,
    required String unit,
    required double? refLow,
    required double? refHigh,
    bool isDesirable = false,
  }) {
    final v = value;
    if (v == null) return null;

    // Un "valore desiderabile" è un obiettivo clinico, non un limite di
    // normalità: starne fuori è normale e non dice nulla sulla lettura.
    if (isDesirable) return null;

    if (v < 0 && refLow != null && refLow >= 0) {
      return const ImplausibleValue(
        kind: ImplausibilityKind.negative,
        message: 'Il valore è negativo, ma il riferimento del referto non '
            'ammette valori sotto lo zero. Potrebbe essere un trattino letto '
            'come segno meno.',
      );
    }

    if (_inside(v, refLow, refHigh)) return null;

    final percentBounded =
        _isPercent(unit) && refHigh != null && refHigh <= 100;

    // Lo spostamento di virgola si applica solo dove un valore dieci volte
    // fuori sarebbe incompatibile con la vita: analiti omeostatici, oppure
    // percentuali che per definizione non superano il 100.
    if (AnalyteCatalog.isHomeostatic(rawName) || percentBounded) {
      final shifted = _decimalShift(v, refLow, refHigh);
      if (shifted != null) {
        return ImplausibleValue(
          kind: ImplausibilityKind.decimalShift,
          suggested: shifted,
          message: 'Fuori scala rispetto al riferimento del referto, ma con la '
              'virgola spostata di una cifra rientrerebbe: '
              '${_format(shifted)} invece di ${_format(v)}.',
        );
      }
    }

    if (percentBounded && v > 100) {
      return ImplausibleValue(
        kind: ImplausibilityKind.impossiblePercentage,
        message: 'Una percentuale non può superare il 100 % quando il '
            'riferimento del referto si ferma a ${_format(refHigh)}.',
      );
    }

    return null;
  }

  /// Comodità per una voce appena estratta da un referto.
  static ImplausibleValue? checkAnalyte(ParsedAnalyte a) => check(
        rawName: a.rawName,
        value: a.value,
        unit: a.unit,
        refLow: a.reference.low,
        refHigh: a.reference.high,
        isDesirable: a.reference.isDesirable,
      );

  static bool _inside(double v, double? low, double? high) {
    if (low != null && v < low) return false;
    if (high != null && v > high) return false;
    return true;
  }

  static bool _isPercent(String unit) => unit.trim() == '%';

  /// Valore corretto se spostare la virgola di una posizione lo riporta ben
  /// dentro l'intervallo, altrimenti `null`.
  ///
  /// Servono entrambi i limiti: con un solo estremo (`< 5` per la PCR) non si
  /// può distinguere una virgola persa da un'infiammazione vera.
  static double? _decimalShift(double v, double? low, double? high) {
    if (low == null || high == null || high <= low) return null;

    final margin = (high - low) * _coreMargin;
    final coreLow = low + margin;
    final coreHigh = high - margin;

    // Prima la divisione: la virgola persa in lettura è l'errore più comune,
    // e produce un valore troppo grande.
    for (final candidate in [v / 10, v * 10]) {
      if (candidate >= coreLow && candidate <= coreHigh) return _tidy(candidate);
    }
    return null;
  }

  /// Toglie il pulviscolo della virgola mobile: `47.199999999999996` non è un
  /// valore da proporre a chi sta correggendo un referto.
  static double _tidy(double v) => double.parse(v.toStringAsFixed(4));

  static String _format(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble() && v.abs() < 1e9) return v.toStringAsFixed(0);
    return '$v'.replaceAll('.', ',');
  }
}
