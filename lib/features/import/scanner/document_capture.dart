/// Acquisizione di un documento con rilevamento automatico dei bordi.
///
/// Fotografare un referto tenendo il telefono in mano produce quasi sempre
/// un'immagine storta, con il foglio inclinato e parte del tavolo intorno.
/// Il riconoscimento del testo peggiora molto in quelle condizioni: le righe
/// della tabella non sono orizzontali e il raggruppamento delle celle, che si
/// basa sull'allineamento verticale, sbaglia.
///
/// Lo scanner di ML Kit individua i bordi del foglio, raddrizza la
/// prospettiva e attenua ombre e riflessi prima di consegnare l'immagine.
library;

import 'document_capture_unsupported.dart'
    if (dart.library.io) 'document_capture_mobile.dart' as impl;

/// Documento acquisito dallo scanner.
class ScannedDocument {
  const ScannedDocument({required this.pagePaths, this.pdfPath});

  /// Pagine raddrizzate, una per immagine, da sottoporre al riconoscimento.
  final List<String> pagePaths;

  /// PDF con tutte le pagine, conservato come documento originale.
  final String? pdfPath;

  bool get isEmpty => pagePaths.isEmpty;
}

/// Errore o rinuncia durante l'acquisizione.
class DocumentCaptureException implements Exception {
  const DocumentCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class DocumentCapture {
  /// `false` dove lo scanner non è disponibile: in quel caso l'importazione
  /// ripiega sulla fotocamera normale.
  Future<bool> get isAvailable;

  /// Avvia l'acquisizione. Restituisce `null` se l'utente rinuncia.
  Future<ScannedDocument?> scan({int pageLimit});

  Future<void> dispose();
}

DocumentCapture createDocumentCapture() => impl.createDocumentCapture();
