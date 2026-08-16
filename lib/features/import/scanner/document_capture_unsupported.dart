import 'document_capture.dart';

/// Piattaforme senza scanner: l'importazione userà la fotocamera normale.
class UnsupportedDocumentCapture implements DocumentCapture {
  const UnsupportedDocumentCapture();

  @override
  Future<bool> get isAvailable async => false;

  @override
  Future<ScannedDocument?> scan({int pageLimit = 1}) async {
    throw const DocumentCaptureException(
      'Acquisizione con rilevamento dei bordi non disponibile su questa '
      'piattaforma.',
    );
  }

  @override
  Future<void> dispose() async {}
}

DocumentCapture createDocumentCapture() => const UnsupportedDocumentCapture();
