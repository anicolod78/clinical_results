/// Riconoscimento del testo su Android con ML Kit.
///
/// Il modello è incorporato nell'applicazione ed esegue localmente: nessuna
/// immagine di referto viene trasmessa.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ocr_service.dart';
import 'text_layout.dart';

class MlKitOcrService implements OcrService {
  MlKitOcrService();

  /// Alfabeto latino: copre l'italiano, che è la lingua dei referti attesi.
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  String get engineName => 'ML Kit (sul dispositivo)';

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<String> recognize({Uint8List? bytes, String? path}) async {
    final imagePath = path ?? await _writeTemporary(bytes);
    if (imagePath == null) {
      throw const OcrException('Nessuna immagine da analizzare.');
    }

    try {
      final recognized = await _recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return _joinPreservingLayout(recognized);
    } catch (e) {
      throw OcrException('Riconoscimento non riuscito: $e');
    } finally {
      // Il file temporaneo conterrebbe un referto in chiaro nella memoria del
      // dispositivo: va rimosso appena il riconoscimento è concluso.
      if (path == null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (file.existsSync()) {
          try {
            await file.delete();
          } on FileSystemException {
            // niente da fare: sarà rimosso con la cache
          }
        }
      }
    }
  }

  Future<String?> _writeTemporary(Uint8List? bytes) async {
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(dir.path, 'ocr_${DateTime.now().microsecondsSinceEpoch}.jpg'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Ricompone il testo a partire dai riquadri riconosciuti.
  ///
  /// ML Kit non restituisce righe di tabella ma frammenti con la loro
  /// posizione: sulle colonne di un referto il nome, il valore, l'intervallo
  /// e l'unità arrivano quasi sempre separati. Il raggruppamento in righe è
  /// in [composeLines], tenuto a parte perché è la parte delicata e va
  /// verificata senza dipendere da un dispositivo.
  String _joinPreservingLayout(RecognizedText recognized) {
    final fragments = <OcrFragment>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        fragments.add(
          OcrFragment(
            text: line.text,
            left: box.left.toDouble(),
            top: box.top.toDouble(),
            right: box.right.toDouble(),
            bottom: box.bottom.toDouble(),
          ),
        );
      }
    }
    return composeLines(fragments);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}

OcrService createOcrService() => MlKitOcrService();
