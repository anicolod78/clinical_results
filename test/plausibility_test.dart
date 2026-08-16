import 'package:clinical_results/features/parsing/plausibility.dart';
import 'package:flutter_test/flutter_test.dart';

ImplausibleValue? check(
  String name,
  double value, {
  String unit = '',
  double? low,
  double? high,
  bool desirable = false,
}) {
  return Plausibility.check(
    rawName: name,
    value: value,
    unit: unit,
    refLow: low,
    refHigh: high,
    isDesirable: desirable,
  );
}

void main() {
  group('segnala un errore di acquisizione', () {
    test('ematocrito 472 % con riferimento 40 - 52', () {
      // Il caso che ha originato il controllo, preso dall'archivio reale.
      final found = check('Ematocrito', 472, unit: '%', low: 40, high: 52);

      expect(found, isNotNull);
      expect(found!.kind, ImplausibilityKind.decimalShift);
      expect(found.suggested, 47.2);
    });

    test('sodio 1400 con riferimento 135 - 145', () {
      final found = check('Sodio', 1400, unit: 'mmol/L', low: 135, high: 145);

      expect(found?.kind, ImplausibilityKind.decimalShift);
      expect(found?.suggested, 140);
    });

    test('emoglobina 150 dove il referto misura in g/dL', () {
      // Il numero sarebbe corretto in g/L, ma l'intervallo dello stesso
      // referto dice che qui si misura in g/dL: la virgola è persa.
      final found = check('Emoglobina', 150, unit: 'g/dL', low: 13.5, high: 17.5);

      expect(found?.kind, ImplausibilityKind.decimalShift);
      expect(found?.suggested, 15);
    });

    test('virgola spostata nell altro senso', () {
      final found = check('Ematocrito', 4.52, unit: '%', low: 40, high: 52);

      expect(found?.kind, ImplausibilityKind.decimalShift);
      expect(found?.suggested, 45.2);
    });

    test('percentuale oltre il 100 anche senza correzione evidente', () {
      // 716 verrebbe da 71,6, che però cade fuori dal riferimento: la
      // correzione non si propone, ma il valore resta impossibile.
      final found = check('Neutrofili', 716, unit: '%', low: 40, high: 70);

      expect(found?.kind, ImplausibilityKind.impossiblePercentage);
    });

    test('valore negativo dove il riferimento non ammette segno', () {
      final found = check('Ferro', -12, unit: 'ug/dL', low: 60, high: 160);

      expect(found?.kind, ImplausibilityKind.negative);
    });
  });

  // La parte che conta. Un avviso che suona sui referti gravi verrebbe
  // ignorato per abitudine, e a quel punto non protegge più da nulla.
  group('tace sui valori alterati ma veri', () {
    test('PCR 200 in una sepsi', () {
      expect(check('Proteina C reattiva', 200, unit: 'mg/L', high: 5), isNull);
    });

    test('PCR 40, che diviso dieci rientrerebbe sotto il limite', () {
      expect(check('PCR', 40, unit: 'mg/L', high: 5), isNull,
          reason: 'con un solo estremo non si distingue una virgola persa '
              'da un valore realmente alto');
    });

    test('ferritina 1200 in un sovraccarico marziale', () {
      expect(check('Ferritina', 1200, unit: 'ng/mL', low: 30, high: 400), isNull);
    });

    test('ALT 300 in un epatite acuta', () {
      expect(check('ALT', 300, unit: 'U/L', low: 5, high: 40), isNull);
    });

    test('TSH 30 in un ipotiroidismo', () {
      expect(check('TSH', 30, unit: 'uUI/mL', low: 0.4, high: 4), isNull);
    });

    test('leucociti 100 in una leucemia', () {
      // Diviso dieci darebbe esattamente il limite superiore: il margine
      // sull intervallo esiste per non toccare questi casi.
      expect(check('Leucociti', 100, unit: 'x10^9/L', low: 4, high: 10), isNull);
    });

    test('piastrine 1500 in una trombocitosi', () {
      expect(check('Piastrine', 1500, unit: 'x10^9/L', low: 150, high: 400),
          isNull);
    });

    test('emoglobina 8 in un anemia grave', () {
      expect(check('Emoglobina', 8, unit: 'g/dL', low: 13.5, high: 17.5), isNull);
    });

    test('sodio 120 in un iponatriemia', () {
      expect(check('Sodio', 120, unit: 'mmol/L', low: 135, high: 145), isNull);
    });
  });

  group('non interviene dove non può sapere', () {
    test('analita sconosciuto al catalogo', () {
      expect(check('Antigene XYZ', 10000, unit: 'U/mL', low: 1, high: 2), isNull,
          reason: 'senza sapere di che esame si tratti non si può dichiarare '
              'impossibile un valore');
    });

    test('valore dentro il riferimento', () {
      expect(check('Ematocrito', 45.2, unit: '%', low: 40, high: 52), isNull);
    });

    test('riferimento desiderabile, che non è un limite di normalità', () {
      expect(
        check('Colesterolo', 250, unit: 'mg/dL', high: 190, desirable: true),
        isNull,
      );
    });

    test('valore non numerico', () {
      expect(
        Plausibility.check(
          rawName: 'Ematocrito',
          value: null,
          unit: '%',
          refLow: 40,
          refHigh: 52,
        ),
        isNull,
      );
    });

    test('nessun riferimento sul referto', () {
      expect(check('Ematocrito', 472, unit: '%'), isNull,
          reason: 'senza intervallo non c è nulla contro cui confrontare');
    });
  });
}
