import 'package:clinical_results/core/db/repositories/series_repository.dart';
import 'package:clinical_results/features/results/merge_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica quali coppie vengono proposte per l'unione.
///
/// I casi negativi contano più di quelli positivi: proporre di unire due
/// esami distinti su una cartella sanitaria significa suggerire di mescolare
/// valori che non hanno nulla in comune, e chi accetta il suggerimento non ha
/// modo di accorgersene in seguito.
void main() {
  AnalyteSeries s(String name, {String unit = '', int points = 3}) =>
      AnalyteSeries(
        canonicalKey: '${name.toLowerCase()}|$unit',
        displayName: name,
        unit: unit,
        group: 'Altro',
        points: List.generate(
          points,
          (i) => MeasurementPoint(
            date: DateTime(2026, 1, i + 1),
            reportId: i,
            measurementId: i,
            value: 1,
          ),
        ),
      );

  group('coppie da non proporre mai', () {
    test('due esami noti e distinti, per quanto somiglianti', () {
      // Un solo carattere separa HDL da LDL, ma sono lipoproteine diverse e
      // il loro significato clinico è addirittura opposto.
      final candidates = findMergeCandidates([
        s('Colesterolo HDL', unit: 'mg/dL'),
        s('Colesterolo LDL', unit: 'mg/dL'),
      ]);
      expect(candidates, isEmpty);
    });

    test('sigle note che differiscono per una lettera', () {
      expect(
        findMergeCandidates([s('ALT (GPT)', unit: 'U/L'), s('AST (GOT)', unit: 'U/L')]),
        isEmpty,
      );
      expect(
        findMergeCandidates([s('MCH', unit: 'pg'), s('MCHC', unit: 'g/dL')]),
        isEmpty,
      );
    });

    test('due nomi entrambi sconosciuti al catalogo', () {
      // Non c'è modo di stabilire quale sia la lettura corretta, e potrebbero
      // essere due esami rari e diversi: HCV e HIV differiscono di poco.
      final candidates = findMergeCandidates([
        s('Anticorpi Anti-HCV'),
        s('Anticorpi Anti-HIV'),
      ]);
      expect(candidates, isEmpty);
    });

    test('stesso esame con unità diverse', () {
      // Percentuale e valore assoluto sono due misure legittime e distinte.
      final candidates = findMergeCandidates([
        s('Linfociti', unit: '%'),
        s('Lifnociti', unit: 'x10^9/L'),
      ]);
      expect(candidates, isEmpty);
    });

    test('nomi troppo corti per giudicare', () {
      expect(findMergeCandidates([s('MCV', unit: 'fL'), s('MCH', unit: 'fL')]),
          isEmpty);
    });

    test('nomi lontani fra loro', () {
      final candidates = findMergeCandidates([
        s('Emoglobina', unit: 'g/dL'),
        s('Creatinina', unit: 'g/dL'),
      ]);
      expect(candidates, isEmpty);
    });
  });

  group('coppie da proporre', () {
    test('due denominazioni note dello stesso analita', () {
      // Caso reale: un referto importato prima che il catalogo imparasse il
      // sinonimo conserva il nome per esteso, perché la denominazione viene
      // registrata all'importazione e non cambia più.
      final candidates = findMergeCandidates([
        s('RDW', unit: '%'),
        s('Indice di anisocitosi corpuscolare', unit: '%'),
      ]);
      expect(candidates, hasLength(1));
      expect(candidates.single.known.displayName, 'RDW',
          reason: 'si tiene il nome che useranno le importazioni future');
    });

    test('vale anche a parti invertite', () {
      final candidates = findMergeCandidates([
        s('Volume corpuscolare medio', unit: 'fL'),
        s('MCV', unit: 'fL'),
      ]);
      expect(candidates, hasLength(1));
      expect(candidates.single.known.displayName, 'MCV');
      expect(candidates.single.misread.displayName, 'Volume corpuscolare medio');
    });

    test('una lettura storpiata accanto a una riconosciuta', () {
      final candidates = findMergeCandidates([
        s('Emoglobina', unit: 'g/dL'),
        s('Enoglobina', unit: 'g/dL'),
      ]);
      expect(candidates, hasLength(1));
      expect(candidates.single.known.displayName, 'Emoglobina');
      expect(candidates.single.misread.displayName, 'Enoglobina');
    });

    test('riconosce lo storpiato a prescindere dall ordine', () {
      final candidates = findMergeCandidates([
        s('Ematocito', unit: '%'),
        s('Ematocrito', unit: '%'),
      ]);
      expect(candidates.single.known.displayName, 'Ematocrito');
      expect(candidates.single.misread.displayName, 'Ematocito');
    });

    test('due caratteri sbagliati su un nome lungo', () {
      final candidates = findMergeCandidates([
        s('Proteina C reattiva (PCR)', unit: 'mg/L'),
        s('Proteina C reattlva (PCB)', unit: 'mg/L'),
      ]);
      expect(candidates, hasLength(1));
    });
  });

  group('avviso su unione manuale', () {
    test('segnala quando entrambi sono esami noti e distinti', () {
      expect(
        bothAreKnownAnalytes(
          s('Colesterolo HDL', unit: 'mg/dL'),
          s('Colesterolo LDL', unit: 'mg/dL'),
        ),
        isTrue,
      );
    });

    test('non segnala se uno dei due è una lettura storpiata', () {
      expect(
        bothAreKnownAnalytes(
          s('Emoglobina', unit: 'g/dL'),
          s('Enoglobina', unit: 'g/dL'),
        ),
        isFalse,
      );
    });
  });
}
