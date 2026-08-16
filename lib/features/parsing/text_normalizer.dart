/// Normalizzazione del testo grezzo prima dell'analisi.
///
/// I referti reali arrivano da due strade con difetti diversi:
///  * estrazione da PDF -> trattini tipografici, apici resi con spazi
///    (`x10 9 /L`), spazi unificatori, sillabazione morbida;
///  * OCR -> confusioni O/0, l/1, virgole decimali, spaziatura irregolare.
///
/// Uniformare qui evita di duplicare casi speciali dentro il parser.
library;

class TextNormalizer {
  const TextNormalizer._();

  /// Caratteri che vanno ricondotti al trattino ASCII.
  ///
  /// I referti APSS 2024/2026 usano U+2212 MINUS SIGN sia nei nomi
  /// (`S−Colesterolo`) sia negli intervalli (`4.0−10.0`).
  static const _dashLike = <int>{
    0x00AD, // soft hyphen
    0x2010, // hyphen
    0x2011, // non-breaking hyphen
    0x2012, // figure dash
    0x2013, // en dash
    0x2014, // em dash
    0x2015, // horizontal bar
    0x2212, // minus sign
    0xFE58, 0xFE63, 0xFF0D,
  };

  /// Spazi "esotici" da ricondurre allo spazio semplice.
  static const _spaceLike = <int>{
    0x00A0, 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005,
    0x2006, 0x2007, 0x2008, 0x2009, 0x200A, 0x202F, 0x205F, 0x3000,
  };

  /// Apici Unicode -> cifra corrispondente, per unità come `x10⁹/L`.
  static const _superscripts = <int, String>{
    0x2070: '0', 0x00B9: '1', 0x00B2: '2', 0x00B3: '3', 0x2074: '4',
    0x2075: '5', 0x2076: '6', 0x2077: '7', 0x2078: '8', 0x2079: '9',
  };

  static final _unitPower = RegExp(r'x\s*10\s*\^?\s*(\d{1,2})\s*/\s*([a-zA-Z]+)');
  static final _multiSpace = RegExp(r'[ \t]+');
  static final _blankLines = RegExp(r'\n{3,}');

  /// Applica tutte le normalizzazioni conservando l'andamento a righe.
  static String normalize(String input) {
    final unified = _unifyCharacters(input);
    var out = unified.replaceAllMapped(
      _unitPower,
      (m) => 'x10^${m[1]}/${m[2]}',
    );
    out = out.replaceAll(_multiSpace, ' ');
    out = out.split('\n').map((l) => l.trim()).join('\n');
    out = out.replaceAll(_blankLines, '\n\n');
    return out.trim();
  }

  static String _unifyCharacters(String input) {
    final buffer = StringBuffer();
    for (final rune in input.replaceAll('\r\n', '\n').replaceAll('\r', '\n').runes) {
      if (_dashLike.contains(rune)) {
        buffer.write('-');
      } else if (_spaceLike.contains(rune)) {
        buffer.write(' ');
      } else if (_superscripts.containsKey(rune)) {
        buffer.write(_superscripts[rune]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Interpreta un numero scritto all'italiana o all'inglese.
  ///
  /// Il separatore decimale nei referti è quasi sempre il punto, ma l'OCR e
  /// alcuni laboratori producono la virgola: entrambi devono dare lo stesso
  /// valore, altrimenti `0,81` diventerebbe `81`.
  static double? parseNumber(String raw) {
    var s = raw.trim().replaceAll(' ', '');
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'^[<>]=?'), '');
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      // Il separatore decimale è l'ultimo dei due; l'altro separa le migliaia.
      s = s.lastIndexOf(',') > s.lastIndexOf('.')
          ? s.replaceAll('.', '').replaceAll(',', '.')
          : s.replaceAll(',', '');
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  /// Normalizza un'unità di misura per il confronto tra referti di anni diversi.
  ///
  /// Senza questo passaggio `x10^9/L` (2024) e `x10 9 /L` (2019) sarebbero
  /// due serie distinte e il grafico dell'emocromo risulterebbe spezzato.
  static String normalizeUnit(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return '';
    u = u.replaceAll(_multiSpace, '');

    // Cifre residue in testa, lasciate dal riconoscimento ottico quando
    // sgrana un estremo dell'intervallo (`0.4x10^9/L`, `4%`).
    //
    // Il taglio va fatto qui, dopo la rimozione degli spazi: prima l'unità
    // può presentarsi come `0.4 x10^9/L`, e cercare la cifra attaccata alla
    // lettera non troverebbe nulla. Nessuna unità reale comincia con una
    // cifra: le potenze si scrivono `x10^9/L`.
    u = u.replaceFirst(RegExp(r'^[\d.,]+(?=[a-zA-Zµ%])'), '');
    u = u.replaceAllMapped(
      RegExp(r'x10\^?(\d{1,2})/([a-zA-Z]+)'),
      (m) => 'x10^${m[1]}/${m[2]!.toUpperCase() == 'L' ? 'L' : m[2]}',
    );
    // Uniforma le varianti di scrittura più comuni.
    const aliases = <String, String>{
      'gr/dl': 'g/dL',
      'g/dl': 'g/dL',
      'mg/dl': 'mg/dL',
      'mg/l': 'mg/L',
      'g/l': 'g/L',
      'u/l': 'U/L',
      'ui/l': 'U/L',
      'fl': 'fL',
      'pg': 'pg',
      'mmol/mol': 'mmol/mol',
      'mm/h': 'mm/h',
      'mmh': 'mm/h',
      'ng/ml': 'ng/mL',
      'pg/ml': 'pg/mL',
      'mcg/dl': 'µg/dL',
      'ug/dl': 'µg/dL',
      // Confusioni ricorrenti del riconoscimento ottico: la barra di
      // separazione viene letta come "l" o come "1". Solo i casi in cui la
      // lettura alternativa non corrisponde a nessuna unità reale, così non
      // si rischia di correggere un'unità valida.
      'gldl': 'g/dL',
      'g1dl': 'g/dL',
      'mgldl': 'mg/dL',
      'mg1dl': 'mg/dL',
      'mgll': 'mg/L',
      'ull': 'U/L',
    };
    final lower = u.toLowerCase();
    return aliases[lower] ?? u;
  }
}
