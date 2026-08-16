/// Individuazione delle serie che sembrano lo stesso esame letto male.
///
/// Il criterio è deliberatamente restrittivo. In medicina moltissime sigle
/// distinte differiscono per una sola lettera — HDL e LDL, HCV e HIV, ALT e
/// AST — e proporre di unirle significherebbe suggerire di fondere due esami
/// diversi in un unico andamento. Su una cartella sanitaria un suggerimento
/// sbagliato è peggio di nessun suggerimento: chi lo accetta si ritrova valori
/// mescolati senza che nulla lo segnali.
///
/// Si suggerisce quindi una coppia solo quando ci sono indizi che una delle
/// due letture sia un errore, non semplicemente che i nomi si somiglino.
library;

import '../../core/db/repositories/series_repository.dart';
import '../parsing/analyte_catalog.dart';

/// Coppia di serie che potrebbero essere lo stesso esame.
typedef MergeCandidate = ({AnalyteSeries misread, AnalyteSeries known});

/// Coppie proposte all'utente.
List<MergeCandidate> findMergeCandidates(List<AnalyteSeries> series) {
  final out = <MergeCandidate>[];

  for (var i = 0; i < series.length; i++) {
    for (var j = i + 1; j < series.length; j++) {
      final candidate = _evaluate(series[i], series[j]);
      if (candidate != null) out.add(candidate);
    }
  }
  return out;
}

MergeCandidate? _evaluate(AnalyteSeries a, AnalyteSeries b) {
  if (a.displayName == b.displayName) return null;

  // Unità diverse significano quasi sempre misure diverse dello stesso
  // elemento, non un errore di lettura: la formula leucocitaria si esprime
  // sia in percentuale sia in valore assoluto e le due serie vanno tenute
  // separate.
  if (a.unit != b.unit) return null;

  final defA = AnalyteCatalog.lookup(a.displayName);
  final defB = AnalyteCatalog.lookup(b.displayName);
  final knownA = defA != null;
  final knownB = defB != null;

  // Due denominazioni diverse dello stesso analita secondo il catalogo: è la
  // proposta più sicura che si possa fare, perché non si basa su una
  // somiglianza ma su un'equivalenza dichiarata. Succede con i referti
  // importati prima che il catalogo imparasse un sinonimo — `RDW` e `Indice
  // di anisocitosi corpuscolare` — perché il nome viene registrato al momento
  // dell'importazione e non cambia più.
  if (knownA && knownB && defA.canonicalName == defB.canonicalName) {
    // Senza indizi su quale sia la forma preferita si tiene quella del
    // catalogo, cioè il nome che le importazioni future useranno.
    final known = a.displayName == defA.displayName ? a : b;
    final other = identical(known, a) ? b : a;
    return (misread: other, known: known);
  }

  // Se il catalogo riconosce entrambi i nomi come analiti diversi, sono due
  // esami reali e distinti. È il caso di HDL e LDL: somigliantissimi nel
  // nome, opposti nel significato, e da non unire mai.
  if (knownA && knownB) return null;

  // Se non riconosce nessuno dei due non c'è modo di stabilire quale sia la
  // lettura corretta, e la somiglianza da sola non basta: potrebbero essere
  // due esami rari e distinti, come due anticorpi diversi.
  if (!knownA && !knownB) return null;

  final misread = knownA ? b : a;
  final known = knownA ? a : b;

  final left = _normalize(misread.displayName);
  final right = _normalize(known.displayName);
  if (left.length < 5 || right.length < 5) return null;

  // Una differenza su nomi lunghi è compatibile con un carattere sbagliato;
  // due lo sono ancora, oltre si entra nel campo delle somiglianze casuali.
  final distance = _editDistance(left, right);
  if (distance == 0 || distance > 2) return null;

  // La differenza deve restare una piccola frazione del nome: su una parola
  // di sei lettere due caratteri diversi sono un'altra parola.
  if (distance / right.length > 0.25) return null;

  return (misread: misread, known: known);
}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Distanza di edit fra due stringhe.
int _editDistance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [
        current[j - 1] + 1,
        previous[j] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}

/// `true` quando entrambe le serie corrispondono a esami noti e distinti.
///
/// Usata per avvertire chi sceglie di unirle comunque a mano.
bool bothAreKnownAnalytes(AnalyteSeries a, AnalyteSeries b) =>
    AnalyteCatalog.lookup(a.displayName) != null &&
    AnalyteCatalog.lookup(b.displayName) != null &&
    AnalyteCatalog.lookup(a.displayName)!.canonicalName !=
        AnalyteCatalog.lookup(b.displayName)!.canonicalName;
