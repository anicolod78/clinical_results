/// Riconoscimento del testo nel browser con tesseract.js.
///
/// Il riconoscimento avviene dentro la pagina, tramite WebAssembly: l'immagine
/// del referto non viene inviata a nessun servizio. Dalla rete arrivano solo
/// la libreria e il modello linguistico, che non contengono dati dell'utente.
///
/// Questa via serve alla piattaforma Web, usata per le prove: su Android il
/// riconoscimento passa da ML Kit, più rapido e già presente sul dispositivo.
library;

import 'dart:convert';
import 'dart:js_interop';
// `getProperty` è definito qui: il risultato di tesseract.js è un oggetto
// JavaScript anonimo, di cui non esiste un tipo dichiarato da interrogare.
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'ocr_service.dart';

@JS('Tesseract')
external JSObject? get _tesseract;

@JS('Tesseract.recognize')
external JSPromise<JSObject> _recognize(JSAny image, JSAny language);

class TesseractOcrService implements OcrService {
  const TesseractOcrService();

  /// Italiano con l'inglese come riserva: sui referti compaiono spesso sigle
  /// e unità in inglese accanto al testo italiano.
  static const _languages = 'ita+eng';

  @override
  String get engineName => 'tesseract.js (nel browser)';

  @override
  Future<bool> get isAvailable async => _tesseract != null;

  @override
  Future<String> recognize({Uint8List? bytes, String? path}) async {
    if (_tesseract == null) {
      throw const OcrException(
        'La libreria di riconoscimento non è stata caricata. '
        'Verificare la connessione oppure importare un PDF con livello testo.',
      );
    }
    if (bytes == null) {
      throw const OcrException('Nessuna immagine da analizzare.');
    }

    try {
      // tesseract.js accetta un data URL: evita di dover creare un elemento
      // immagine nel documento solo per passare i byte.
      final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
      final result = await _recognize(dataUrl.toJS, _languages.toJS).toDart;

      final data = result.getProperty<JSObject?>('data'.toJS);
      final text = data?.getProperty<JSString?>('text'.toJS);
      if (text == null) {
        throw const OcrException('Il riconoscimento non ha prodotto testo.');
      }
      return text.toDart;
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException('Riconoscimento non riuscito: $e');
    }
  }

  @override
  Future<void> dispose() async {}
}

OcrService createOcrService() => const TesseractOcrService();
