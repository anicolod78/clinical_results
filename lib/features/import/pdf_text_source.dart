/// Estrazione del testo da un PDF.
///
/// Molti referti scaricati dal fascicolo sanitario elettronico sono PDF
/// "digitali": contengono già il testo e non serve alcun OCR. Provare prima
/// questa strada è nettamente più accurato che rasterizzare e riconoscere,
/// oltre che immediato.
///
/// Quando il PDF è invece la scansione di un foglio il livello testo è vuoto:
/// in quel caso occorre passare all'OCR sulle pagine rasterizzate.
library;

import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Esito dell'estrazione, con l'informazione se serva ricorrere all'OCR.
class PdfExtraction {
  const PdfExtraction({
    required this.text,
    required this.pageCount,
    required this.needsOcr,
  });

  final String text;
  final int pageCount;

  /// `true` quando il PDF non ha un livello testo utilizzabile.
  final bool needsOcr;
}

class PdfTextSource {
  const PdfTextSource();

  /// Numero minimo di caratteri sotto il quale si considera che il PDF non
  /// abbia un vero livello testo: alcune scansioni contengono solo una
  /// filigrana o un piè di pagina generato.
  static const _minUsefulChars = 80;

  PdfExtraction extract(Uint8List bytes) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      final text = PdfTextExtractor(document).extractText(layoutText: true);
      final meaningful = text.replaceAll(RegExp(r'\s'), '');
      return PdfExtraction(
        text: text,
        pageCount: pageCount,
        needsOcr: meaningful.length < _minUsefulChars,
      );
    } finally {
      document?.dispose();
    }
  }
}
