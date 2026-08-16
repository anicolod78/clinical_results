/// Percorso di importazione: scelta dell'origine, estrazione, revisione.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../review/review_screen.dart';
import 'import_service.dart';
import 'ocr/ocr_service.dart';

/// Avvia l'importazione di un referto per il paziente indicato.
Future<void> startImport(
  BuildContext context,
  WidgetRef ref,
  int patientId,
) async {
  final source = await showModalBottomSheet<ImportSource>(
    context: context,
    builder: (_) => const _SourceSheet(),
  );
  if (source == null || !context.mounted) return;

  final service = ref.read(importServiceProvider);

  final PickedDocument? document;
  try {
    document = await service.pick(source);
  } catch (e) {
    if (context.mounted) _showError(context, 'Selezione non riuscita: $e');
    return;
  }
  if (document == null || !context.mounted) return;

  // L'estrazione può richiedere qualche secondo, soprattutto con il
  // riconoscimento ottico: senza un segnale l'app sembrerebbe bloccata.
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  // Il navigator radice è quello su cui viene inserito il dialogo: chiudere
  // il dialogo con quello locale rischierebbe di chiudere invece la schermata
  // sottostante, se nel frattempo il dialogo si fosse già congedato.
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  var waitingDialogOpen = true;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const _BusyDialog(),
    ).whenComplete(() => waitingDialogOpen = false),
  );

  ExtractionResult? result;
  Object? failure;
  try {
    result = await service.extract(document);
  } catch (e) {
    failure = e;
  }

  if (waitingDialogOpen) rootNavigator.pop();

  if (failure != null) {
    final message = failure is OcrException
        ? failure.message
        : 'Estrazione non riuscita: $failure';
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
    return;
  }

  await navigator.push(
    MaterialPageRoute(
      builder: (_) => ReviewScreen(patientId: patientId, extraction: result!),
    ),
  );
}

/// Indicatore di attesa durante la lettura del documento.
class _BusyDialog extends StatelessWidget {
  const _BusyDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 20),
          Expanded(child: Text('Lettura del referto in corso…')),
        ],
      ),
    );
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // `SafeArea` tiene le voci sopra la barra di navigazione: senza, l'ultima
    // opzione finirebbe sotto e sarebbe difficile da toccare.
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Da dove arriva il referto?',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('File PDF'),
            subtitle: const Text(
              'La via più affidabile: i valori vengono letti dal testo',
            ),
            onTap: () => Navigator.of(context).pop(ImportSource.pdf),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Immagine dalla galleria'),
            subtitle: const Text('Foto o scansione già salvata'),
            onTap: () => Navigator.of(context).pop(ImportSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Scansiona il referto'),
            subtitle: const Text(
              'Riconosce i bordi del foglio e lo raddrizza; più fogli in una '
              'sola volta',
            ),
            onTap: () => Navigator.of(context).pop(ImportSource.camera),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
