/// Controllo di plausibilità applicato a una misura già archiviata.
///
/// Differisce da quello della revisione per una ragione sola, ma decisiva: qui
/// esiste la storia del paziente. Se il referto non riportava l'intervallo di
/// riferimento — o il riconoscimento da foto l'ha perso, cosa che accade sulla
/// stessa riga in cui sbaglia il valore — lo si recupera dalle altre misure
/// della stessa serie.
///
/// Senza questo recupero il controllo tacerebbe proprio nei casi peggiori:
/// quelli in cui la lettura ha fallito due volte sulla stessa riga.
library;

import '../../core/db/repositories/series_repository.dart';
import '../parsing/plausibility.dart';

ImplausibleValue? checkStoredPoint(
  AnalyteSeries series,
  MeasurementPoint point,
) {
  // L'intervallo della misura stessa ha sempre la precedenza: viene dal
  // documento che ha prodotto quel valore. Si ripiega sulla serie solo quando
  // manca del tutto, senza mai mescolare un estremo letto con uno inferito.
  final hasOwn = point.refLow != null || point.refHigh != null;
  final typical = hasOwn ? null : series.typicalReference;

  return Plausibility.check(
    rawName: series.displayName,
    value: point.value,
    unit: series.unit,
    refLow: hasOwn ? point.refLow : typical?.low,
    refHigh: hasOwn ? point.refHigh : typical?.high,
    isDesirable: point.isDesirable,
  );
}
