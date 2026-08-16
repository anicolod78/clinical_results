/// Il controllo di plausibilità su misure già archiviate.
///
/// Nasce da un fallimento concreto: nell'archivio reale un ematocrito di
/// `472 %` non veniva segnalato. Tutte le regole richiedono un intervallo di
/// riferimento, e quella misura non ne aveva: il riconoscimento da foto aveva
/// perso la colonna dell'intervallo sulla stessa riga in cui aveva sbagliato
/// il valore. Erano lo stesso difetto di lettura, e insieme rendevano il dato
/// impossibile da verificare.
library;

import 'package:clinical_results/core/db/repositories/series_repository.dart';
import 'package:clinical_results/core/db/tables.dart';
import 'package:clinical_results/features/parsing/plausibility.dart';
import 'package:clinical_results/features/results/stored_value_check.dart';
import 'package:flutter_test/flutter_test.dart';

MeasurementPoint point(
  int day,
  double value, {
  double? low,
  double? high,
  StoredReferenceKind kind = StoredReferenceKind.range,
}) {
  return MeasurementPoint(
    date: DateTime(2026, 1, day),
    reportId: day,
    measurementId: day,
    value: value,
    refLow: low,
    refHigh: high,
    refKind: low == null && high == null ? StoredReferenceKind.none : kind,
  );
}

AnalyteSeries series(List<MeasurementPoint> points, {
  String name = 'Ematocrito',
  String unit = '%',
}) {
  return AnalyteSeries(
    canonicalKey: 'ematocrito|%',
    displayName: name,
    unit: unit,
    group: 'Emocromo',
    points: points,
  );
}

void main() {
  group('intervallo recuperato dalla serie', () {
    test('segnala una misura priva di intervallo usando le altre', () {
      final rotta = point(3, 472);
      final s = series([
        point(1, 44.1, low: 40, high: 52),
        point(2, 45.8, low: 40, high: 52),
        rotta,
        point(4, 45.2, low: 40, high: 52),
      ]);

      final found = checkStoredPoint(s, rotta);

      expect(found, isNotNull,
          reason: 'è il caso reale che il controllo non intercettava');
      expect(found!.kind, ImplausibilityKind.decimalShift);
      expect(found.suggested, 47.2);
    });

    test('senza altre misure con intervallo non inventa nulla', () {
      final rotta = point(3, 472);
      final s = series([point(1, 44.1), rotta]);

      expect(checkStoredPoint(s, rotta), isNull);
    });

    test('prende la coppia più frequente, non la più recente', () {
      // Un solo referto letto male non deve dettare il riferimento agli altri.
      final rotta = point(9, 472);
      final s = series([
        point(1, 44.1, low: 40, high: 52),
        point(2, 45.8, low: 40, high: 52),
        point(3, 44.0, low: 40, high: 52),
        point(4, 45.0, low: 4, high: 5200), // lettura sballata dell intervallo
        rotta,
      ]);

      expect(s.typicalReference, (low: 40.0, high: 52.0));
      expect(checkStoredPoint(s, rotta)?.suggested, 47.2);
    });

    test('l intervallo della misura stessa ha la precedenza', () {
      // Anche quando la serie ne suggerirebbe un altro: quello del documento
      // che ha prodotto il valore resta la fonte migliore.
      final propria = point(3, 47.2, low: 41, high: 53);
      final s = series([
        point(1, 44.1, low: 40, high: 52),
        point(2, 45.8, low: 40, high: 52),
        propria,
      ]);

      expect(checkStoredPoint(s, propria), isNull);
    });

    test('non si mescola un estremo letto con uno inferito', () {
      // Una misura con il solo limite superiore resta giudicata su quello:
      // completarla con il limite inferiore di un altro prelievo creerebbe un
      // intervallo che non è mai stato stampato su nessun referto.
      final parziale = point(3, 472, high: 52, kind: StoredReferenceKind.upperBound);
      final s = series([
        point(1, 44.1, low: 40, high: 52),
        point(2, 45.8, low: 40, high: 52),
        parziale,
      ]);

      final found = checkStoredPoint(s, parziale);
      expect(found?.kind, ImplausibilityKind.impossiblePercentage,
          reason: 'la regola della percentuale basta col solo limite alto, '
              'quella della virgola no');
    });
  });

  group('il recupero non allarga le segnalazioni', () {
    test('ferritina 1200 resta un valore vero anche col riferimento inferito', () {
      final alta = point(3, 1200);
      final s = series([
        point(1, 210, low: 30, high: 400),
        point(2, 260, low: 30, high: 400),
        alta,
      ], name: 'Ferritina', unit: 'ng/mL');

      expect(checkStoredPoint(s, alta), isNull);
    });

    test('leucociti 100 in una leucemia', () {
      final alta = point(3, 100);
      final s = series([
        point(1, 6.2, low: 4, high: 10),
        point(2, 7.1, low: 4, high: 10),
        alta,
      ], name: 'Leucociti', unit: 'x10^9/L');

      expect(checkStoredPoint(s, alta), isNull);
    });
  });
}
