/// Riconoscimento del testo da immagini.
///
/// L'implementazione cambia con la piattaforma ma il contratto no:
///
///  * Android usa ML Kit, che riconosce il testo interamente sul dispositivo;
///  * il browser usa tesseract.js, anch'esso in esecuzione locale.
///
/// In nessuno dei due casi l'immagine di un referto lascia il dispositivo.
/// È un requisito, non un dettaglio: inviare un referto a un servizio di
/// riconoscimento remoto significherebbe comunicare dati sanitari a terzi.
library;

import 'dart:typed_data';

import 'ocr_unsupported.dart'
    if (dart.library.io) 'ocr_mobile.dart'
    if (dart.library.js_interop) 'ocr_web.dart' as impl;

/// Motore di riconoscimento del testo.
abstract class OcrService {
  /// Nome del motore, mostrato nei messaggi diagnostici.
  String get engineName;

  /// Alcune piattaforme non hanno un motore utilizzabile: in quel caso la UI
  /// deve proporre l'inserimento manuale invece di fallire e basta.
  Future<bool> get isAvailable;

  /// Riconosce il testo di un'immagine.
  ///
  /// Va fornito [path] oppure [bytes]: su Android il percorso evita una copia
  /// in memoria, nel browser esistono solo i byte.
  Future<String> recognize({Uint8List? bytes, String? path});

  Future<void> dispose();
}

/// Errore del riconoscimento, con un messaggio già leggibile dall'utente.
class OcrException implements Exception {
  const OcrException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Costruisce il motore adatto alla piattaforma corrente.
OcrService createOcrService() => impl.createOcrService();
