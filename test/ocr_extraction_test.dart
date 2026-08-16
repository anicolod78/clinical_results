import 'package:clinical_results/features/import/ocr/text_layout.dart';
import 'package:clinical_results/features/parsing/models.dart';
import 'package:clinical_results/features/parsing/report_parser.dart';
import 'package:clinical_results/features/parsing/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica il percorso "foto -> testo -> valori".
///
/// Il riconoscimento ottico produce un testo strutturato in modo diverso da
/// quello di un PDF: le colonne della tabella arrivano come frammenti
/// separati, e il valore non è incollato al nome dell'esame. Questi test
/// riproducono quella forma.
void main() {
  const parser = ReportParser();

  OcrFragment frag(String text, double left, double top,
          {double height = 40, double width = 200}) =>
      OcrFragment(
        text: text,
        left: left,
        top: top,
        right: left + width,
        bottom: top + height,
      );

  group('ricomposizione delle righe dai riquadri', () {
    test('unisce le celle della stessa riga anche se disallineate', () {
      // Foto scattata a mano: le celle di una riga non sono mai perfettamente
      // allineate, qui differiscono di 14 pixel su righe alte 40.
      final text = composeLines([
        frag('Leucociti', 100, 500),
        frag('5.8', 700, 508),
        frag('x10^9/L', 900, 514),
        frag('(4.0-10.0)', 1200, 505),
        frag('Piastrine', 100, 580),
        frag('187', 700, 588),
        frag('x10^9/L', 900, 585),
        frag('(150-400)', 1200, 592),
      ]);

      expect(text, 'Leucociti 5.8 x10^9/L (4.0-10.0)\n'
          'Piastrine 187 x10^9/L (150-400)');
    });

    test('non fonde righe distinte', () {
      final text = composeLines([
        frag('Emoglobina', 100, 500),
        frag('15.5', 700, 500),
        frag('Ematocrito', 100, 560),
        frag('45.2', 700, 560),
      ]);
      expect(text.split('\n'), hasLength(2));
    });

    test('ordina le celle da sinistra a destra, non nell ordine di lettura', () {
      // ML Kit restituisce spesso i blocchi per colonna: prima tutti i nomi,
      // poi tutti i valori.
      final text = composeLines([
        frag('x10^9/L', 900, 500),
        frag('Leucociti', 100, 502),
        frag('(4.0-10.0)', 1200, 498),
        frag('5.8', 700, 501),
      ]);
      expect(text, 'Leucociti 5.8 x10^9/L (4.0-10.0)');
    });

    test('la soglia si adatta alla dimensione del testo', () {
      // Immagine ridotta: righe alte 10 pixel, distanti 15.
      final text = composeLines([
        frag('Leucociti', 10, 50, height: 10, width: 30),
        frag('5.8', 70, 52, height: 10, width: 15),
        frag('Piastrine', 10, 65, height: 10, width: 30),
        frag('187', 70, 66, height: 10, width: 15),
      ]);
      expect(text, 'Leucociti 5.8\nPiastrine 187');
    });

    test('nessun frammento produce testo vuoto', () {
      expect(composeLines([]), '');
    });
  });

  group('analisi del testo prodotto dal riconoscimento ottico', () {
    test('interpreta le righe ricomposte con le colonne separate', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
EMATOLOGIA
Sg-Emocromo
Leucociti 5.8 x10^9/L (4.0-10.0)
Emoglobina 15.5 g/dL (13.5-18.0)
Piastrine 187 x10^9/L (150-400)
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(3));
      expect(r.analytes[0].displayName, 'Leucociti');
      expect(r.analytes[0].value, 5.8);
      expect(r.analytes[0].unit, 'x10^9/L');
      expect(r.analytes[0].reference.low, 4.0);
      expect(r.analytes[2].value, 187);
      // L'unico avviso ammesso è quello sulla data, assente in questo
      // frammento di testo.
      expect(
        r.warnings.where((w) => w.contains('non interpretata')),
        isEmpty,
        reason: r.warnings.join(' | '),
      );
    });

    test('recupera il valore quando finisce su una riga tutta sua', () {
      // Caso frequente quando la foto è storta e le celle non si allineano.
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
Leucociti
5.8
x10^9/L
(4.0-10.0)
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(1),
          reason: 'il valore non deve andare perso: ${r.warnings.join(' | ')}');
      expect(r.analytes.single.displayName, 'Leucociti');
      expect(r.analytes.single.value, 5.8);
      expect(r.analytes.single.unit, 'x10^9/L');
      expect(r.analytes.single.reference.high, 10.0);
    });

    test('non scarta un valore intero isolato scambiandolo per numero di pagina',
        () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
Piastrine
187
x10^9/L
(150-400)
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(1),
          reason: 'un intero da solo è un valore, non un piè di pagina');
      expect(r.analytes.single.value, 187);
    });

    test('continua a scartare i veri numeri di pagina', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
Leucociti 5.8 x10^9/L (4.0-10.0)
0
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(1));
    });

    test('legge il referto della foto di esempio', () {
      // Trascrizione fedele di esempi/photo_2026-08-15_18-53-47.jpg dopo la
      // ricomposizione delle righe. Due differenze rispetto ai PDF: le
      // colonne sono nell'ordine nome, valore, intervallo, unità, e i nomi
      // sono per esteso invece che in sigla. Manca anche l'intestazione
      // della tabella, quindi il parser deve ripiegare sull'intero testo.
      const text = '''
EMATOLOGIA
Emocromo con formula
Leucociti 6.4 4 - 10 x10^9/L
Eritrociti 5.15 4.5 - 5.8 x10^12/L
Emoglobina 17.0 13.5 - 18 g/dL
Ematocrito 47.2 40 - 52 %
Volume corpuscolare medio 91.7 79 - 96 fL
Emoglobina corpuscolare media 33.0 27 - 33 pg
Concentrazione emoglobinica corpuscolare 36.0 31 - 36 g/dL
Indice di anisocitosi corpuscolare 12.9 < 15 %
Piastrine 200 150 - 400 x10^9/L
Neutrofili assoluti 4.1 1.6 - 7 x10^9/L
Neutrofili % 64.7 40 - 70 %
Linfociti assoluti 1.5 1 - 4 x10^9/L
Linfociti % 23.6 20 - 45 %
Monociti assoluti 0.7 0.2 - 0.8 x10^9/L
Monociti % 10.2 > 3 - 10 %
Eosinofili assoluti 0.1 0 - 0.4 x10^9/L
Eosinofili % 0.9 0 - 4 %
Basofili assoluti 0.0 0 - 0.1 x10^9/L
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(18),
          reason: 'avvisi: ${r.warnings.join(' | ')}');

      ParsedAnalyte byName(String name, {String? unit}) => r.analytes.firstWhere(
            (a) =>
                a.displayName == name && (unit == null || a.unit == unit),
            orElse: () => throw StateError(
                'mancante: $name${unit == null ? '' : ' ($unit)'} — '
                'presenti: ${r.analytes.map((a) => '${a.displayName}/${a.unit}').join(', ')}'),
          );

      // L'unità sta dopo l'intervallo e non deve andare persa.
      final leucociti = byName('Leucociti');
      expect(leucociti.value, 6.4);
      expect(leucociti.unit, 'x10^9/L');
      expect(leucociti.reference.low, 4);
      expect(leucociti.reference.high, 10);

      // Nomi per esteso ricondotti alla sigla del catalogo.
      expect(byName('MCV').value, 91.7);
      expect(byName('MCV').unit, 'fL');
      expect(byName('MCH').value, 33.0);
      expect(byName('MCHC').value, 36.0);

      final rdw = byName('RDW');
      expect(rdw.value, 12.9);
      expect(rdw.unit, '%');
      expect(rdw.reference.kind, ReferenceKind.upperBound);
      expect(rdw.reference.high, 15);

      // Le due misure della formula restano distinte e usano le stesse
      // chiavi dei referti in PDF, così le serie storiche si uniscono.
      expect(byName('Neutrofili', unit: 'x10^9/L').canonicalKey,
          'neutrofili|x10^9/L');
      expect(byName('Neutrofili', unit: '%').canonicalKey, 'neutrofili|%');
      expect(byName('Neutrofili', unit: 'x10^9/L').value, 4.1);
      expect(byName('Neutrofili', unit: '%').value, 64.7);

      // Il simbolo di fuori norma non deve essere scambiato per la soglia.
      final monociti = byName('Monociti', unit: '%');
      expect(monociti.value, 10.2);
      expect(monociti.reference.low, 3);
      expect(monociti.reference.high, 10);
      expect(monociti.flag, ValueFlag.high);

      expect(byName('Emoglobina').flag, ValueFlag.normal);
      expect(
        r.warnings.where((w) => w.contains('non interpretata')),
        isEmpty,
        reason: r.warnings.join(' | '),
      );
    });

    test('recupera l intervallo quando il trattino non viene riconosciuto', () {
      // Riscontrato sul dispositivo: ML Kit perde il trattino sottile fra i
      // due estremi su alcune righe della stessa foto. Senza recupero
      // l'intervallo finiva nell'unità, che diventava "13.518gldL".
      const text = '''
Emoglobina 17.0 13.5 18 g/dL
Ematocrito 47.2 40 52 %
Volume corpuscolare medio 91.7 79 96 fL
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(3));

      final hb = r.analytes[0];
      expect(hb.value, 17.0);
      expect(hb.unit, 'g/dL');
      expect(hb.reference.low, 13.5);
      expect(hb.reference.high, 18);
      expect(hb.flag, ValueFlag.normal);

      expect(r.analytes[1].unit, '%');
      expect(r.analytes[1].reference.low, 40);
      expect(r.analytes[2].displayName, 'MCV');
      expect(r.analytes[2].unit, 'fL');
      expect(r.analytes[2].reference.high, 96);
    });

    test('non lascia cifre dell intervallo attaccate all unità', () {
      // Riscontrato sul dispositivo: un estremo sgranato dal riconoscimento
      // lasciava unità come "0.4x10^9/L" e "4%", che avrebbero prodotto una
      // serie storica separata dallo stesso esame letto da un PDF.
      const text = '''
Esame Risultato
Eosinofili assoluti 0.1 0 - 0.4 x10^9/L
Eosinofili % 0.9 0 - 4 %
''';
      final r = parser.parse(text);
      expect(r.analytes, hasLength(2));
      expect(r.analytes[0].unit, 'x10^9/L');
      expect(r.analytes[0].canonicalKey, 'eosinofili|x10^9/L');
      expect(r.analytes[1].unit, '%');
      expect(r.analytes[1].canonicalKey, 'eosinofili|%');
    });

    test('toglie le cifre in testa anche se separate da uno spazio', () {
      // Forma effettivamente osservata sul dispositivo: la cifra residua era
      // staccata dall'unità, e veniva riattaccata solo dopo la rimozione
      // degli spazi. Il primo tentativo di correzione non la intercettava.
      expect(TextNormalizer.normalizeUnit('0.4 x10^9/L'), 'x10^9/L');
      expect(TextNormalizer.normalizeUnit('4 %'), '%');
      expect(TextNormalizer.normalizeUnit('0.4x10^9/L'), 'x10^9/L');
      // Le unità legittime non devono essere toccate.
      expect(TextNormalizer.normalizeUnit('x10^9/L'), 'x10^9/L');
      expect(TextNormalizer.normalizeUnit('mL/min/1,73'), 'mL/min/1,73');
      expect(TextNormalizer.normalizeUnit('g/dL'), 'g/dL');
    });

    test('normalizza le unità sporcate dal riconoscimento', () {
      const text = '''
Esame Risultato
Emoglobina corpuscolare media 33.0 27 - 33 Pg
Concentrazione emoglobinica corpuscolare 36.0 31 - 36 g/dL.
''';
      final r = parser.parse(text);
      expect(r.analytes[0].unit, 'pg', reason: 'maiuscola da correggere');
      expect(r.analytes[1].unit, 'g/dL', reason: 'punto finale da togliere');
    });

    test('ricongiunge la serie quando l unità è troncata dall OCR', () {
      // Riscontrato in tabella sul dispositivo: MCV compariva due volte, con
      // unità "f" dalla foto e "fL" dai PDF, spezzando lo storico in due
      // righe. La `L` era stata persa dal riconoscimento.
      final daFoto = parser.parse(
        'Esame Risultato\nVolume corpuscolare medio 91.7 79 - 96 f\n',
      ).analytes.single;
      final daPdf = parser.parse(
        'Esame Risultato\nMCV92.2 fL (79.0-96.0)\n',
      ).analytes.single;

      expect(daFoto.unit, 'fL', reason: 'il troncamento va riparato');
      expect(daFoto.canonicalKey, daPdf.canonicalKey,
          reason: 'foto e PDF devono confluire nella stessa serie');
    });

    test('ricava la percentuale dal nome se la colonna unità è persa', () {
      // Riscontrato in tabella: dalla foto "Neutrofili %" arrivava senza
      // unità perché il riconoscimento aveva perso il "%" finale della riga,
      // e la misura si separava da quella letta dal PDF.
      final senzaUnita = parser.parse(
        'Esame Risultato\nNeutrofili % 64.7 40 - 70\n',
      ).analytes.single;
      final daPdf = parser.parse(
        'Esame Risultato\nNeutrofili61.7 % (40.0-70.0)\n',
      ).analytes.single;

      expect(senzaUnita.unit, '%');
      expect(senzaUnita.canonicalKey, daPdf.canonicalKey);
      expect(senzaUnita.canonicalKey, 'neutrofili|%');
    });

    test('non attribuisce la percentuale a un nome che non la dichiara', () {
      final r = parser.parse(
        'Esame Risultato\nNeutrofili assoluti 4.1 1.6 - 7\n',
      );
      expect(r.analytes.single.unit, isEmpty,
          reason: '"assoluti" non dice in quale scala');
    });

    test('non altera un unità semplicemente diversa da quella attesa', () {
      // Un laboratorio potrebbe misurare in una scala diversa: sostituire
      // l'unità falserebbe il dato.
      final r = parser.parse(
        'Esame Risultato\nEmoglobina 155 130 - 180 g/L\n',
      );
      expect(r.analytes.single.unit, 'g/L');
    });

    test('non inventa un unità quando il referto non la riporta', () {
      final r = parser.parse('Esame Risultato\nPiastrine 200 150 - 400\n');
      expect(r.analytes.single.unit, isEmpty);
    });

    test('non inventa un intervallo da due numeri in ordine decrescente', () {
      final r = parser.parse('Esame Risultato\nQualcosa 5.0 90 12 unita\n');
      expect(r.analytes.single.reference.isEmpty, isTrue,
          reason: '90 12 non è un intervallo plausibile');
    });

    test('non scambia le cifre di un unità composta per un intervallo', () {
      final r = parser.parse(
        'Esame Risultato\nS-eGFR Stima Filtrato Glomerulare 105 mL/min/1,73\n',
      );
      expect(r.analytes.single.value, 105);
      expect(r.analytes.single.reference.isEmpty, isTrue);
    });

    test('tollera la virgola decimale del riconoscimento ottico', () {
      const text = '''
Esame Risultato Unità di misura Intervalli di riferimento
Creatinina
0,81
mg/dL
(0,73-1,18)
''';
      final r = parser.parse(text);
      expect(r.analytes.single.value, 0.81);
      expect(r.analytes.single.reference.low, 0.73);
    });
  });
}
