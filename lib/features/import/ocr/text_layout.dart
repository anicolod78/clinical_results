/// Ricomposizione del testo a partire dai riquadri riconosciuti.
///
/// Il riconoscimento ottico restituisce frammenti con la loro posizione, non
/// righe di tabella. Su un referto le colonne (esame, risultato, unità,
/// intervallo) finiscono in frammenti separati, e ricomporli nell'ordine
/// sbagliato rende il documento illeggibile per il parser.
///
/// Qui i frammenti vengono raggruppati in righe e uniti con uno spazio, così
/// il testo prodotto somiglia a quello di un PDF: una riga per esame, con
/// nome, valore, unità e intervallo in successione.
library;

/// Frammento riconosciuto, con il riquadro che lo racchiude.
class OcrFragment {
  const OcrFragment({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;
  double get centerY => (top + bottom) / 2;
}

/// Unisce i frammenti in righe di testo.
///
/// Due frammenti appartengono alla stessa riga quando i loro centri verticali
/// distano meno di una frazione dell'altezza del testo. La soglia è relativa e
/// non assoluta: una foto ad alta risoluzione ha righe alte decine di pixel,
/// una immagine ridotta poche, e una soglia fissa funzionerebbe solo per una
/// delle due. Nelle foto scattate a mano le celle della stessa riga sono
/// inoltre quasi sempre leggermente disallineate.
String composeLines(List<OcrFragment> fragments) {
  if (fragments.isEmpty) return '';

  final ordered = [...fragments]..sort((a, b) => a.centerY.compareTo(b.centerY));

  // L'altezza mediana rappresenta il testo del corpo meglio della media, che
  // verrebbe falsata dalle intestazioni in caratteri grandi.
  final heights = ordered.map((f) => f.height).where((h) => h > 0).toList()
    ..sort();
  final referenceHeight = heights.isEmpty
      ? 1.0
      : heights[heights.length ~/ 2];
  final tolerance = referenceHeight * 0.6;

  final rows = <List<OcrFragment>>[];
  for (final fragment in ordered) {
    final current = rows.isEmpty ? null : rows.last;
    if (current != null &&
        (fragment.centerY - _rowCenter(current)).abs() <= tolerance) {
      current.add(fragment);
    } else {
      rows.add([fragment]);
    }
  }

  return rows
      .map(
        (row) => (row..sort((a, b) => a.left.compareTo(b.left)))
            .map((f) => f.text.trim())
            .where((t) => t.isNotEmpty)
            .join(' '),
      )
      .where((line) => line.isNotEmpty)
      .join('\n');
}

double _rowCenter(List<OcrFragment> row) =>
    row.map((f) => f.centerY).reduce((a, b) => a + b) / row.length;
