import 'dart:typed_data';

import 'ocr_service.dart';

/// Segnaposto per piattaforme prive di motore di riconoscimento.
class UnsupportedOcrService implements OcrService {
  const UnsupportedOcrService();

  @override
  String get engineName => 'non disponibile';

  @override
  Future<bool> get isAvailable async => false;

  @override
  Future<String> recognize({Uint8List? bytes, String? path}) async {
    throw const OcrException(
      'Il riconoscimento del testo non è disponibile su questa piattaforma. '
      'Importare un PDF con livello testo oppure inserire i valori a mano.',
    );
  }

  @override
  Future<void> dispose() async {}
}

OcrService createOcrService() => const UnsupportedOcrService();
