/// Acquisizione di un referto e sua trasformazione in dati.
///
/// Il percorso è sempre lo stesso: si ottiene un documento, se ne ricava il
/// testo, lo si analizza. Cambia solo il modo di ricavare il testo:
///
///  * PDF con livello testo -> lettura diretta, la via più fedele;
///  * PDF scansionato o foto -> riconoscimento ottico.
///
/// Si tenta sempre prima la lettura diretta: quando il PDF contiene già il
/// testo, il riconoscimento ottico non farebbe che introdurre errori dove
/// non ce n'erano.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/db/tables.dart';
import '../parsing/models.dart';
import '../parsing/report_parser.dart';
import 'ocr/ocr_service.dart';
import 'pdf_text_source.dart';
import 'scanner/document_capture.dart';

/// Origine da cui l'utente vuole acquisire il referto.
enum ImportSource { camera, gallery, pdf }

/// Documento acquisito, prima di qualunque elaborazione.
class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.bytes,
    required this.kind,
    this.path,
    this.pages = const [],
  });

  final String name;

  /// Contenuto completo: viene conservato nel database, quindi cifrato,
  /// per poter risalire in seguito all'origine di ogni valore.
  final Uint8List bytes;

  /// Percorso sul dispositivo, quando disponibile. Permette a ML Kit di
  /// leggere il file senza una seconda copia in memoria.
  final String? path;

  final SourceKind kind;

  /// Pagine da sottoporre al riconoscimento, quando sono più di una.
  ///
  /// Valorizzato dallo scanner, che può restituire più fogli. Quando è vuoto
  /// si usa [path] o [bytes], cioè l'unica immagine acquisita.
  final List<String> pages;
}

/// Esito dell'estrazione, con l'indicazione di come è stato ottenuto.
class ExtractionResult {
  const ExtractionResult({
    required this.report,
    required this.document,
    required this.method,
    required this.usedOcr,
  });

  final ParsedReport report;
  final PickedDocument document;

  /// Descrizione della via seguita, mostrata all'utente in revisione: sapere
  /// se un valore viene dal testo del PDF o da un riconoscimento ottico
  /// cambia quanta attenzione merita il controllo.
  final String method;

  final bool usedOcr;
}

class ImportService {
  ImportService({
    OcrService? ocr,
    DocumentCapture? capture,
    ImagePicker? imagePicker,
    ReportParser parser = const ReportParser(),
    PdfTextSource pdfSource = const PdfTextSource(),
  }) : _ocr = ocr ?? createOcrService(),
       _capture = capture ?? createDocumentCapture(),
       _imagePicker = imagePicker ?? ImagePicker(),
       _parser = parser,
       _pdf = pdfSource;

  final OcrService _ocr;
  final DocumentCapture _capture;
  final ImagePicker _imagePicker;
  final ReportParser _parser;
  final PdfTextSource _pdf;

  OcrService get ocr => _ocr;

  /// Chiede all'utente il documento da importare.
  ///
  /// Restituisce `null` se l'operazione viene annullata.
  Future<PickedDocument?> pick(ImportSource source) async {
    switch (source) {
      case ImportSource.camera:
        return _scanDocument();
      case ImportSource.gallery:
        return _pickImage(ImageSource.gallery);
      case ImportSource.pdf:
        return _pickPdf();
    }
  }

  /// Acquisisce con lo scanner, ripiegando sulla fotocamera normale dove non
  /// è disponibile.
  Future<PickedDocument?> _scanDocument() async {
    if (!await _capture.isAvailable) {
      return _pickImage(ImageSource.camera);
    }

    final scanned = await _capture.scan();
    if (scanned == null || scanned.isEmpty) return null;

    // Si conserva il PDF prodotto dallo scanner, che raccoglie tutte le
    // pagine raddrizzate in un solo documento. La prima immagine è il
    // ripiego quando il PDF non viene generato.
    final pdfPath = scanned.pdfPath;
    final originalPath = pdfPath ?? scanned.pagePaths.first;
    final bytes = await File(_stripFileScheme(originalPath)).readAsBytes();

    return PickedDocument(
      name: 'Scansione ${scanned.pagePaths.length > 1 ? ''
          '(${scanned.pagePaths.length} pagine)' : ''}'.trim(),
      bytes: bytes,
      // Resta un documento fotografato: il PDF prodotto dallo scanner non ha
      // livello testo, e va comunque riconosciuto otticamente.
      kind: SourceKind.image,
      pages: scanned.pagePaths.map(_stripFileScheme).toList(),
    );
  }

  /// Lo scanner restituisce percorsi con lo schema `file://`.
  static String _stripFileScheme(String path) =>
      path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;

  Future<PickedDocument?> _pickImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      // Il testo minuto dei referti si perde se l'immagine viene ridotta
      // troppo: si limita solo la dimensione estrema delle fotocamere recenti.
      maxWidth: 3000,
      imageQuality: 92,
    );
    if (file == null) return null;
    return PickedDocument(
      name: file.name,
      bytes: await file.readAsBytes(),
      path: _pathIfUsable(file.path),
      kind: SourceKind.image,
    );
  }

  Future<PickedDocument?> _pickPdf() async {
    const type = XTypeGroup(
      label: 'Referti PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
    );
    final file = await openFile(acceptedTypeGroups: [type]);
    if (file == null) return null;
    return PickedDocument(
      name: file.name,
      bytes: await file.readAsBytes(),
      path: _pathIfUsable(file.path),
      kind: SourceKind.pdf,
    );
  }

  /// Nel browser `path` è un blob URL, inutilizzabile come file.
  String? _pathIfUsable(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('blob:') || path.startsWith('http')) return null;
    return path;
  }

  /// Ricava il testo dal documento e lo analizza.
  Future<ExtractionResult> extract(PickedDocument document) async {
    // Le pagine dello scanner vanno riconosciute anche se il documento
    // conservato è un PDF: quel PDF è fatto di immagini e non ha livello
    // testo, quindi la lettura diretta non troverebbe nulla.
    if (document.pages.isNotEmpty) {
      return _extractFromPages(document);
    }
    if (document.kind == SourceKind.pdf) {
      return _extractFromPdf(document);
    }
    return _extractFromImage(document, 'Foto');
  }

  /// Riconosce più pagine e ne unisce il testo.
  Future<ExtractionResult> _extractFromPages(PickedDocument document) async {
    await _requireOcr();

    final buffer = StringBuffer();
    for (final page in document.pages) {
      final text = await _ocr.recognize(path: page);
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(text);
    }

    final pages = document.pages.length;
    return ExtractionResult(
      report: _parser.parse(buffer.toString(), fileName: document.name),
      document: document,
      method: 'Scansione con rilevamento bordi, '
          '$pages ${pages == 1 ? 'pagina' : 'pagine'}, ${_ocr.engineName}',
      usedOcr: true,
    );
  }

  Future<void> _requireOcr() async {
    if (await _ocr.isAvailable) return;
    throw OcrException(
      'Riconoscimento del testo non disponibile (${_ocr.engineName}). '
      'Importare un PDF con livello testo oppure inserire i valori a mano.',
    );
  }

  Future<ExtractionResult> _extractFromPdf(PickedDocument document) async {
    final extraction = _pdf.extract(document.bytes);

    if (!extraction.needsOcr) {
      return ExtractionResult(
        report: _parser.parse(extraction.text, fileName: document.name),
        document: document,
        method: 'Testo del PDF (${extraction.pageCount} pag.)',
        usedOcr: false,
      );
    }

    // PDF privo di livello testo: è la scansione di un foglio. Le pagine
    // andrebbero convertite in immagini e riconosciute; finché non è
    // disponibile, conviene dirlo chiaramente invece di restituire un
    // risultato vuoto che sembrerebbe un difetto dell'applicazione.
    throw const OcrException(
      'Questo PDF non contiene testo: è la scansione di un documento. '
      'Fotografare il referto e importarlo come immagine, oppure inserire '
      'i valori manualmente.',
    );
  }

  Future<ExtractionResult> _extractFromImage(
    PickedDocument document,
    String label,
  ) async {
    if (!await _ocr.isAvailable) {
      throw OcrException(
        'Riconoscimento del testo non disponibile (${_ocr.engineName}). '
        'Importare un PDF con livello testo oppure inserire i valori a mano.',
      );
    }

    final text = await _ocr.recognize(
      bytes: document.path == null ? document.bytes : null,
      path: document.path,
    );

    return ExtractionResult(
      report: _parser.parse(text, fileName: document.name),
      document: document,
      method: '$label, ${_ocr.engineName}',
      usedOcr: true,
    );
  }

  Future<void> dispose() async {
    await _ocr.dispose();
    await _capture.dispose();
  }
}
