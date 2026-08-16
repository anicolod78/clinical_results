// Utility di sviluppo: mostra cosa il parser estrae dai referti in esempi/.
// Non è un test di verifica (le asserzioni stanno in report_parser_test.dart),
// serve a ispezionare rapidamente l'esito su nuovi formati di referto.
//
//   flutter test test/dump_samples_test.dart
//
// La stampa su console è il risultato stesso di questo strumento.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:clinical_results/features/import/pdf_text_source.dart';
import 'package:clinical_results/features/parsing/models.dart';
import 'package:clinical_results/features/parsing/report_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dir = Directory('esempi');

  test('ispeziona i referti di esempio', () {
    const parser = ReportParser();
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.toLowerCase().endsWith('.pdf')) continue;
      final name = f.uri.pathSegments.last;
      final extraction = const PdfTextSource().extract(f.readAsBytesSync());
      final r = parser.parse(extraction.text, fileName: name);

      print('=' * 78);
      print('$name  (${extraction.pageCount} pag., OCR necessario: ${extraction.needsOcr})');
      print('Paziente : ${r.patient.fullName} / ${r.patient.fiscalCode} / '
          'nato il ${_d(r.patient.birthDate)} / sesso ${r.patient.sex}');
      print('Prelievo : ${_d(r.examDate)}  [fonte: ${r.examDateLabel}]');
      print('Candidate: ${r.dateCandidates.join('  |  ')}');
      print('Esami    : ${r.analytes.length}');
      print('-' * 78);
      String? section;
      for (final a in r.analytes) {
        if (a.section != section) {
          section = a.section;
          print('  [$section]');
        }
        final flag = switch (a.flag) {
          ValueFlag.high => 'ALTO',
          ValueFlag.low => 'BASSO',
          ValueFlag.normal => '',
          ValueFlag.unknown => '?',
        };
        print('  ${a.displayName.padRight(30)} '
            '${(a.value?.toString() ?? a.rawValue ?? '').padLeft(8)} '
            '${a.unit.padRight(10)} ${a.reference.label.padRight(22)} $flag');
      }
      if (r.warnings.isNotEmpty) {
        print('  AVVISI: ${r.warnings.join(' | ')}');
      }
      print('');
    }
  }, skip: dir.existsSync() ? false : 'cartella esempi/ non presente');
}

String _d(DateTime? d) =>
    d == null ? '—' : '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
