/// Scanner documenti di ML Kit (Android).
///
/// L'interfaccia di acquisizione è fornita da Google Play Services e gira in
/// una propria attività: individua i bordi del foglio in tempo reale, corregge
/// la prospettiva, raddrizza l'orientamento e permette di ritoccare il
/// ritaglio prima di confermare.
///
/// Non serve dichiarare il permesso della fotocamera: l'acquisizione avviene
/// fuori dall'applicazione, che riceve soltanto le immagini già pronte.
library;

import 'dart:io';

import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import 'document_capture.dart';

class MlKitDocumentCapture implements DocumentCapture {
  DocumentScanner? _scanner;

  @override
  Future<bool> get isAvailable async => Platform.isAndroid;

  @override
  Future<ScannedDocument?> scan({int pageLimit = 5}) async {
    // Più pagine perché i referti di laboratorio sono spesso su due fogli, e
    // acquisirli separatamente li spezzerebbe in due importazioni distinte.
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: {DocumentFormat.jpeg, DocumentFormat.pdf},
        pageLimit: pageLimit,
        mode: ScannerMode.full,
        isGalleryImport: true,
      ),
    );
    _scanner = scanner;

    try {
      final result = await scanner.scanDocument();
      final pages = result.images ?? const <String>[];
      if (pages.isEmpty) return null;
      return ScannedDocument(pagePaths: pages, pdfPath: result.pdf?.uri);
    } on Exception catch (e) {
      // La rinuncia dell'utente arriva come eccezione dal canale nativo: non
      // è un errore da segnalare.
      if (_looksLikeCancellation(e)) return null;
      throw DocumentCaptureException('Acquisizione non riuscita: $e');
    }
  }

  static bool _looksLikeCancellation(Exception e) {
    final text = e.toString().toLowerCase();
    return text.contains('cancel') || text.contains('annull');
  }

  @override
  Future<void> dispose() async {
    await _scanner?.close();
    _scanner = null;
  }
}

DocumentCapture createDocumentCapture() => MlKitDocumentCapture();
