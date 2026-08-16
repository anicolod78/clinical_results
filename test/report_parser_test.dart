import 'dart:io';

import 'package:clinical_results/features/import/pdf_text_source.dart';
import 'package:clinical_results/features/parsing/models.dart';
import 'package:clinical_results/features/parsing/report_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const parser = ReportParser();

ParsedAnalyte? find(ParsedReport r, String display, {String? unit}) {
  for (final a in r.analytes) {
    if (a.displayName.toLowerCase() == display.toLowerCase() &&
        (unit == null || a.unit == unit)) {
      return a;
    }
  }
  return null;
}

ParsedReport parseSample(String fileName) {
  final file = File('esempi/$fileName');
  final extraction = const PdfTextSource().extract(file.readAsBytesSync());
  expect(extraction.needsOcr, isFalse, reason: '$fileName dovrebbe avere il livello testo');
  return parser.parse(extraction.text, fileName: fileName);
}

void main() {
  // I referti reali contengono dati sanitari personali e non sono versionati:
  // i test su file mancanti vengono saltati invece di fallire.
  final hasSamples = Directory('esempi').existsSync();

  group('normalizzazione e casi sintetici', () {
    test('riconosce il layout su riga singola con nome incollato al valore', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
EMATOLOGIA
Sg−Emocromo
Leucociti5.0 x10 9 /L (4.0−10.0)
Piastrine180 x10 9 /L (150−400)
RDW13.1 % (<= 14.9)
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(3));

      final leu = r.analytes[0];
      expect(leu.displayName, 'Leucociti');
      expect(leu.value, 5.0);
      expect(leu.unit, 'x10^9/L', reason: 'gli apici resi con spazi vanno ricomposti');
      expect(leu.reference.kind, ReferenceKind.range);
      expect(leu.reference.low, 4.0);
      expect(leu.reference.high, 10.0);
      expect(leu.flag, ValueFlag.normal);

      final rdw = r.analytes[2];
      expect(rdw.reference.kind, ReferenceKind.upperBound);
      expect(rdw.reference.high, 14.9);
      expect(rdw.flag, ValueFlag.normal);
    });

    test('riconosce il layout 2019 con unità e intervallo su righe separate', () {
      const text = '''
 Esame Valore Unità di misura Intervalli di riferimento
- EMATOLOGIA -
B-EMOCROMO
 Leucociti7.9
x10^9/L
4.0 - 10.0
 Piastrine228
x10^9/L
150 - 400
 RDW12.8
%
<15
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(3));
      expect(r.analytes[0].value, 7.9);
      expect(r.analytes[0].unit, 'x10^9/L');
      expect(r.analytes[0].reference.high, 10.0);
      expect(r.analytes[1].value, 228);
      expect(r.analytes[2].reference.kind, ReferenceKind.upperBound);
      expect(r.analytes[2].reference.high, 15);
    });

    test('separa le serie quando lo stesso analita ha unità diverse', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
Neutrofili61.7 % (40.0−70.0)
Neutrofili3.1 x10 9 /L (1.6−7.0)
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(2));
      expect(
        r.analytes[0].canonicalKey,
        isNot(r.analytes[1].canonicalKey),
        reason: 'percentuale e valore assoluto non sono la stessa serie storica',
      );
      expect(r.analytes[0].canonicalKey, 'neutrofili|%');
      expect(r.analytes[1].canonicalKey, 'neutrofili|x10^9/L');
    });

    test('stacca la sezione incollata al primo esame', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
CHIMICA CLINICAS−Colesterolo
229 mg/dL Valore desiderabile: <190
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(1));
      expect(r.analytes.single.displayName, 'Colesterolo totale');
      expect(r.analytes.single.value, 229);
      expect(r.analytes.single.section, 'CHIMICA CLINICA');
      expect(r.analytes.single.reference.kind, ReferenceKind.desirableUpper);
      expect(
        r.analytes.single.flag,
        ValueFlag.aboveTarget,
        reason: 'superare un obiettivo va mostrato: la soglia è stampata sul '
            'referto e il grafico la disegna',
      );
      expect(
        r.analytes.single.flag,
        isNot(ValueFlag.high),
        reason: 'ma resta uno stato distinto dal fuori intervallo: un valore '
            'desiderabile è un obiettivo terapeutico, non un limite di '
            'normalità di laboratorio',
      );
    });

    test('riconosce anche un obiettivo mancato per difetto', () {
      // L'HDL ha l'obiettivo rovesciato: si desidera stare sopra la soglia.
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
S−Colesterolo HDL32 mg/dL Valore desiderabile: >40
''';
      final r = parser.parse(text);
      expect(r.analytes.single.reference.kind, ReferenceKind.desirableLower);
      expect(r.analytes.single.flag, ValueFlag.belowTarget);
      expect(r.analytes.single.flag, isNot(ValueFlag.low));
    });

    test('non scambia una nota del laboratorio per un esame', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
S−Glucosio78 mg/dL (70−99)
Alterata glicemia a digiuno per valori compresi tra 100 e 125Diabete Mellito per valori = o > 126
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(1));
      expect(r.analytes.single.value, 78);
      expect(r.analytes.single.note, isNotNull);
    });

    test('ricompone un nome spezzato dalla nota di metodo', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
S−ALT (Alan. Amino Transf.)(
Metodo calibrato IFCC )
25 U/L (10−65)
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(1));
      expect(r.analytes.single.displayName, 'ALT (GPT)');
      expect(r.analytes.single.value, 25);
      expect(r.analytes.single.unit, 'U/L');
      expect(r.analytes.single.reference.low, 10);
      expect(r.analytes.single.reference.high, 65);
    });

    test('interpreta la virgola decimale come separatore', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
S−Creatinina0,81 mg/dL (0,73−1,18)
''';
      final r = parser.parse(text);
      expect(r.analytes.single.value, 0.81);
      expect(r.analytes.single.reference.low, 0.73);
    });

    test('segnala quando la data va chiesta all utente', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
Leucociti5.0 x10 9 /L (4.0−10.0)
''';
      final r = parser.parse(text);
      expect(r.requiresManualDate, isTrue);
      expect(r.warnings, isNotEmpty);
    });
  }, skip: false);

  group('referti reali', () {
    test('emocromo 2019 (layout a tre righe)', () {
      final r = parseSample('2019-09-16 emocromo x piastrine.pdf');

      // L'anagrafica viene verificata per forma e non per valore: i referti in
      // esempi/ sono documenti reali, e scrivere qui il nome e il codice
      // fiscale attesi li porterebbe nella cronologia di git, dove non si
      // rimuovono più. La forma basta a dimostrare che l'estrazione funziona.
      expect(
        r.patient.fiscalCode,
        matches(RegExp(r'^[A-Z]{6}\d{2}[A-Z]\d{2}[A-Z]\d{3}[A-Z]$')),
        reason: 'il codice fiscale deve essere estratto e normalizzato',
      );
      expect(r.patient.fullName, contains(' '),
          reason: 'cognome e nome devono essere entrambi presenti');
      expect(r.patient.birthDate, isNotNull);
      expect(r.examDate, DateTime(2019, 9, 16));

      expect(find(r, 'Leucociti')!.value, 7.9);
      expect(find(r, 'Emoglobina')!.value, 14.4);
      expect(find(r, 'Piastrine')!.value, 228);
      expect(find(r, 'Piastrine')!.unit, 'x10^9/L');
      expect(find(r, 'Piastrine')!.reference.low, 150);
      expect(find(r, 'Piastrine')!.reference.high, 400);

      // Lo stesso nome con due unità deve produrre due voci distinte.
      expect(find(r, 'Neutrofili', unit: '%')!.value, 71.6);
      expect(find(r, 'Neutrofili', unit: 'x10^9/L')!.value, 5.7);

      expect(r.analytes, hasLength(19));
      expect(r.warnings, isEmpty, reason: r.warnings.join('\n'));
    });

    test('VES e PCR 2019, valori fuori soglia', () {
      final r = parseSample('2019-09-20 analisi ves e pcr.pdf');
      expect(r.examDate, DateTime(2019, 9, 20));
      expect(r.analytes, hasLength(2));

      final ves = find(r, 'VES')!;
      expect(ves.value, 23);
      expect(ves.unit, 'mm/h');
      expect(ves.reference.high, 35);
      expect(ves.flag, ValueFlag.normal);

      final pcr = find(r, 'Proteina C reattiva (PCR)')!;
      expect(pcr.value, 22.5);
      expect(pcr.unit, 'mg/L');
      expect(pcr.reference.high, 6);
      expect(pcr.flag, ValueFlag.high);
    });

    test('referto 2024 su due pagine, con lipidi e ALT', () {
      final r = parseSample('82323785.pdf');
      expect(r.examDate, DateTime(2024, 12, 23));

      expect(find(r, 'Leucociti')!.value, 5.0);
      expect(find(r, 'Piastrine')!.value, 180);
      expect(find(r, 'RDW')!.reference.high, 14.9);

      final col = find(r, 'Colesterolo totale')!;
      expect(col.value, 229);
      expect(col.unit, 'mg/dL');
      expect(col.reference.kind, ReferenceKind.desirableUpper);
      expect(col.reference.high, 190);

      expect(find(r, 'Colesterolo HDL')!.value, 61);
      expect(find(r, 'Trigliceridi')!.value, 106);
      expect(find(r, 'ALT (GPT)')!.value, 25);
      expect(r.warnings, isEmpty, reason: r.warnings.join('\n'));
    });

    test('referto 2026: preferisce la data del prelievo', () {
      final r = parseSample('92392763.pdf');
      expect(r.examDate, DateTime(2026, 7, 30));
      expect(r.examDateLabel, 'Prelievo');

      expect(find(r, 'Emoglobina')!.value, 15.5);
      expect(find(r, 'Glucosio (glicemia)')!.value, 78);
      expect(find(r, 'Creatinina')!.value, 0.81);
      expect(find(r, 'Proteine totali')!.value, 70);
      expect(find(r, 'ALT (GPT)')!.value, 27);

      final tg = find(r, 'Trigliceridi')!;
      expect(tg.value, 275);
      expect(tg.reference.kind, ReferenceKind.desirableUpper);

      expect(find(r, 'eGFR (filtrato glomerulare)')!.value, 105);
      expect(r.warnings, isEmpty, reason: r.warnings.join('\n'));
    });

    test('lo stesso analita è confrontabile tra referti di anni diversi', () {
      final a = parseSample('2019-09-16 emocromo x piastrine.pdf');
      final b = parseSample('82323785.pdf');
      final keyA = find(a, 'Piastrine')!.canonicalKey;
      final keyB = find(b, 'Piastrine')!.canonicalKey;
      expect(
        keyA,
        keyB,
        reason: 'senza chiave comune il grafico storico risulterebbe spezzato',
      );
    });
  }, skip: hasSamples ? false : 'cartella esempi/ non presente');
}
