import 'dart:io';

import 'package:clinical_results/core/db/database.dart';
import 'package:clinical_results/core/db/repositories/patient_repository.dart';
import 'package:clinical_results/core/db/repositories/report_repository.dart';
import 'package:clinical_results/core/db/repositories/series_repository.dart';
import 'package:clinical_results/core/db/tables.dart';
import 'package:clinical_results/features/import/pdf_text_source.dart';
import 'package:clinical_results/features/parsing/models.dart';
import 'package:clinical_results/features/parsing/report_parser.dart';
// Si importa solo `native.dart`: `drift.dart` esporta `isNull`/`isNotNull`,
// che collidono con gli omonimi matcher dei test.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Percorso completo: referto reale -> parser -> archivio -> serie storica.
///
/// Il database è in memoria e non cifrato: la cifratura è verificata a parte
/// in database_encryption_test.dart, qui interessa la correttezza dei dati.
void main() {
  late AppDatabase db;
  late PatientRepository patients;
  late ReportRepository reports;
  late SeriesRepository series;

  final hasSamples = Directory('esempi').existsSync();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    patients = PatientRepository(db);
    reports = ReportRepository(db);
    series = SeriesRepository(db);
  });

  tearDown(() => db.close());

  ParsedReport parseSample(String name) {
    final bytes = File('esempi/$name').readAsBytesSync();
    final text = const PdfTextSource().extract(bytes).text;
    return const ReportParser().parse(text, fileName: name);
  }

  Future<int> importSample(int patientId, String name) async {
    final parsed = parseSample(name);
    return reports.save(
      patientId: patientId,
      examDate: parsed.examDate!,
      analytes: parsed.analytes,
      sourceKind: SourceKind.pdf,
      sourceName: name,
      laboratory: parsed.laboratory,
      reportNumber: parsed.reportNumber,
      rawText: parsed.rawText,
    );
  }

  group('anagrafica', () {
    test('crea e ritrova un paziente dal codice fiscale', () async {
      final id = await patients.create(
        fullName: 'ROSSI MARIO',
        fiscalCode: 'rSSMRA80A01H501u',
        birthDate: DateTime(1980, 1, 1),
        sex: 'M',
      );

      final found = await patients.byFiscalCode('RSSMRA80A01H501U');
      expect(found?.id, id);
      expect(found?.fiscalCode, 'RSSMRA80A01H501U',
          reason: 'il codice fiscale va normalizzato in maiuscolo');
    });

    test('cercare un codice fiscale assente non trova nulla', () async {
      await patients.create(fullName: 'Mario Rossi');
      expect(await patients.byFiscalCode('RSSMRA80A01H501U'), isNull);
      expect(await patients.byFiscalCode(''), isNull);
    });
  });

  group('archiviazione dei referti', () {
    test('salva referto e misure in modo coerente', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      final reportId = await importSample(
        patientId,
        '2019-09-16 emocromo x piastrine.pdf',
      );

      final measurements = await reports.measurementsOf(reportId);
      expect(measurements, hasLength(19));

      final piastrine =
          measurements.firstWhere((m) => m.displayName == 'Piastrine');
      expect(piastrine.value, 228);
      expect(piastrine.unit, 'x10^9/L');
      expect(piastrine.refLow, 150);
      expect(piastrine.refHigh, 400);
      expect(piastrine.refKind, StoredReferenceKind.range);
      expect(piastrine.patientId, patientId);
    });

    test('conserva il tipo di riferimento desiderabile', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      final reportId = await importSample(patientId, '82323785.pdf');

      final measurements = await reports.measurementsOf(reportId);
      final colesterolo = measurements
          .firstWhere((m) => m.displayName == 'Colesterolo totale');
      expect(colesterolo.refKind, StoredReferenceKind.desirableUpper);
      expect(colesterolo.refHigh, 190);
    });

    test('riconosce un referto già importato', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');

      final duplicate = await reports.findDuplicate(
        patientId: patientId,
        examDate: DateTime(2019, 9, 16),
      );
      expect(duplicate, isNotNull,
          reason: 'reimportare lo stesso referto sdoppierebbe i punti '
              'sul grafico');
      expect(duplicate!.measurementCount, 19);
    });

    test('non segnala come duplicato un prelievo di un altro giorno', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');

      final duplicate = await reports.findDuplicate(
        patientId: patientId,
        examDate: DateTime(2019, 9, 20),
      );
      expect(duplicate, isNull);
    });

    test('non confonde i referti di pazienti diversi', () async {
      final a = await patients.create(fullName: 'Paziente A');
      final b = await patients.create(fullName: 'Paziente B');
      await importSample(a, '2019-09-16 emocromo x piastrine.pdf');

      expect(
        await reports.findDuplicate(
          patientId: b,
          examDate: DateTime(2019, 9, 16),
        ),
        isNull,
      );
    });

    test('eliminare un paziente rimuove referti e misure', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');

      await patients.delete(patientId);

      final remaining = await db.select(db.measurements).get();
      expect(remaining, isEmpty,
          reason: 'i dati sanitari non devono sopravvivere al paziente');
      expect(await db.select(db.reports).get(), isEmpty);
    });
  });

  group('serie storiche', () {
    test('unisce nel tempo lo stesso analita di referti diversi', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');
      await importSample(patientId, '2019-09-20 emocromo x piastrine.pdf');

      final table = await series.loadTable(patientId);
      expect(table.dates, hasLength(2));
      expect(table.dates.first, DateTime(2019, 9, 20),
          reason: 'le colonne partono dal prelievo più recente');

      final piastrine =
          table.series.firstWhere((s) => s.displayName == 'Piastrine');
      expect(piastrine.points.map((p) => p.value).toList(), [228, 293],
          reason: 'i punti devono essere in ordine cronologico');
      expect(piastrine.lastDelta, 65);
    });

    test('tiene separate le serie con unità diverse', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');

      final table = await series.loadTable(patientId);
      final neutrofili =
          table.series.where((s) => s.displayName == 'Neutrofili').toList();

      expect(neutrofili, hasLength(2),
          reason: 'percentuale e valore assoluto sono misure diverse');
      final units = neutrofili.map((s) => s.unit).toSet();
      expect(units, {'%', 'x10^9/L'});
    });

    test('collega referti a distanza di anni sullo stesso analita', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');
      await importSample(patientId, '82323785.pdf');
      await importSample(patientId, '92392763.pdf');

      final table = await series.loadTable(patientId);
      final emoglobina =
          table.series.firstWhere((s) => s.displayName == 'Emoglobina');

      expect(emoglobina.points, hasLength(3),
          reason: 'formati di referto diversi devono confluire in una serie');
      expect(
        emoglobina.points.map((p) => p.date.year).toList(),
        [2019, 2024, 2026],
      );
    });

    test('distingue il fuori intervallo dall obiettivo mancato', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-20 analisi ves e pcr.pdf');
      await importSample(patientId, '82323785.pdf');

      final table = await series.loadTable(patientId);

      final pcr = table.series
          .firstWhere((s) => s.displayName.startsWith('Proteina C reattiva'));
      expect(pcr.latest!.flag, ValueFlag.high);

      final colesterolo =
          table.series.firstWhere((s) => s.displayName == 'Colesterolo totale');
      expect(colesterolo.latest!.flag, ValueFlag.aboveTarget,
          reason: 'la soglia è stampata sul referto: superarla va mostrato');
      expect(colesterolo.latest!.flag, isNot(ValueFlag.high),
          reason: 'ma con uno stato proprio, perché un obiettivo terapeutico '
              'non è un limite di normalità di laboratorio');
      expect(colesterolo.latest!.isDesirable, isTrue);
    });

    test('raggruppa gli analiti per pannello', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '92392763.pdf');

      final table = await series.loadTable(patientId);
      final groups = table.byGroup.keys.toList();

      expect(groups, contains('Emocromo'));
      expect(groups, contains('Lipidi'));
      expect(groups.indexOf('Emocromo'), lessThan(groups.indexOf('Lipidi')),
          reason: 'l ordine dei gruppi deve essere stabile e prevedibile');
    });

    test('ordina per data del referto, non per ordine di importazione',
        () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');

      // Importazione volutamente in ordine sparso: prima il 2024, poi il
      // 2026, infine il 2019. È il caso reale di chi recupera vecchi referti
      // dopo aver già inserito i più recenti.
      await importSample(patientId, '82323785.pdf');
      await importSample(patientId, '92392763.pdf');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');

      final table = await series.loadTable(patientId);

      // Colonne della tabella: dalla più recente alla più antica.
      expect(
        table.dates,
        [DateTime(2026, 7, 30), DateTime(2024, 12, 23), DateTime(2019, 9, 16)],
        reason: 'le colonne devono seguire la data del prelievo',
      );

      // Punti del grafico: in ordine cronologico crescente, perché l'asse
      // del tempo scorre da sinistra a destra.
      final emoglobina =
          table.series.firstWhere((s) => s.displayName == 'Emoglobina');
      expect(
        emoglobina.points.map((p) => p.date).toList(),
        [DateTime(2019, 9, 16), DateTime(2024, 12, 23), DateTime(2026, 7, 30)],
        reason: 'il grafico deve seguire il tempo, non l ordine di inserimento',
      );
      expect(emoglobina.points.map((p) => p.value).toList(), [14.4, 15.5, 15.5]);

      // La variazione mostrata accanto al grafico confronta le due misure
      // più recenti nel tempo, non le ultime due inserite.
      expect(emoglobina.latest!.date, DateTime(2026, 7, 30));
      expect(emoglobina.lastDelta, 0.0);
    });

    test('unisce due serie tenute separate da un errore di lettura', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');

      // Simula una lettura storpiata dello stesso esame in un secondo
      // referto: nome diverso, quindi chiave diversa.
      await reports.save(
        patientId: patientId,
        examDate: DateTime(2020, 1, 15),
        sourceKind: SourceKind.image,
        analytes: [
          const ParsedAnalyte(
            rawName: 'Emoglobira',
            canonicalKey: 'emoglobira|g/dL',
            displayName: 'Emoglobira',
            unit: 'g/dL',
            reference: ReferenceRange.none(),
            value: 15.1,
          ),
        ],
      );

      var table = await series.loadTable(patientId);
      final storpiata =
          table.series.firstWhere((s) => s.displayName == 'Emoglobira');
      final corretta =
          table.series.firstWhere((s) => s.displayName == 'Emoglobina');
      expect(corretta.points, hasLength(1), reason: 'partono separate');

      await series.mergeSeries(source: storpiata, target: corretta);

      table = await series.loadTable(patientId);
      expect(
        table.series.where((s) => s.displayName == 'Emoglobira'),
        isEmpty,
        reason: 'la lettura storpiata sparisce dalla vista',
      );
      final unita =
          table.series.firstWhere((s) => s.displayName == 'Emoglobina');
      expect(unita.points.map((p) => p.value).toList(), [14.4, 15.1],
          reason: 'i valori confluiscono in ordine cronologico');
    });

    test('l unione è reversibile e non altera le misure', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await importSample(patientId, '2019-09-16 emocromo x piastrine.pdf');
      await reports.save(
        patientId: patientId,
        examDate: DateTime(2020, 1, 15),
        sourceKind: SourceKind.image,
        analytes: [
          const ParsedAnalyte(
            rawName: 'Emoglobira',
            canonicalKey: 'emoglobira|g/dL',
            displayName: 'Emoglobira',
            unit: 'g/dL',
            reference: ReferenceRange.none(),
            value: 15.1,
          ),
        ],
      );

      var table = await series.loadTable(patientId);
      await series.mergeSeries(
        source: table.series.firstWhere((s) => s.displayName == 'Emoglobira'),
        target: table.series.firstWhere((s) => s.displayName == 'Emoglobina'),
      );
      await series.undoMerge('emoglobira|g/dL');

      table = await series.loadTable(patientId);
      expect(
        table.series.where((s) => s.displayName == 'Emoglobira'),
        hasLength(1),
        reason: 'annullando, la serie originale torna visibile',
      );

      // Il dato archiviato non è mai stato riscritto.
      final stored = await db.select(db.measurements).get();
      final raw = stored.where((m) => m.rawName == 'Emoglobira');
      expect(raw, hasLength(1));
      expect(raw.single.canonicalKey, 'emoglobira|g/dL',
          reason: 'la misura conserva la chiave con cui è stata acquisita');
    });

    test('segue una catena di unioni senza restare bloccata', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      for (final (name, value) in [('Alfa', 1.0), ('Beta', 2.0), ('Gamma', 3.0)]) {
        await reports.save(
          patientId: patientId,
          examDate: DateTime(2020, 1, name.length),
          sourceKind: SourceKind.manual,
          analytes: [
            ParsedAnalyte(
              rawName: name,
              canonicalKey: name.toLowerCase(),
              displayName: name,
              unit: '',
              reference: const ReferenceRange.none(),
              value: value,
            ),
          ],
        );
      }

      var table = await series.loadTable(patientId);
      AnalyteSeries byName(String n) =>
          table.series.firstWhere((s) => s.displayName == n);

      // Alfa -> Beta e Beta -> Gamma: tutto deve confluire in Gamma.
      await series.mergeSeries(source: byName('Alfa'), target: byName('Beta'));
      await series.mergeSeries(source: byName('Beta'), target: byName('Gamma'));

      table = await series.loadTable(patientId);
      expect(table.series, hasLength(1));
      expect(table.series.single.displayName, 'Gamma');
      expect(table.series.single.points, hasLength(3));
    });

    test('la tabella di un paziente senza referti è vuota', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      final table = await series.loadTable(patientId);
      expect(table.isEmpty, isTrue);
      expect(table.dates, isEmpty);
    });
  }, skip: hasSamples ? false : 'cartella esempi/ non presente');

  // Non dipende dai referti reali: le misure si costruiscono a mano, così il
  // gruppo resta verificabile anche senza la cartella esempi/.
  group('correzione di una misura archiviata', () {
    Future<int> saveTwo(int patientId) async {
      return reports.save(
        patientId: patientId,
        examDate: DateTime(2026, 2, 3),
        sourceKind: SourceKind.image,
        analytes: [
          const ParsedAnalyte(
            rawName: 'Ematocrito',
            canonicalKey: 'ematocrito|%',
            displayName: 'Ematocrito',
            unit: '%',
            reference: ReferenceRange(
              kind: ReferenceKind.range,
              raw: '40 - 52',
              low: 40,
              high: 52,
            ),
            value: 472, // la virgola persa in lettura
          ),
          const ParsedAnalyte(
            rawName: 'Emoglobina',
            canonicalKey: 'emoglobina|g/dL',
            displayName: 'Emoglobina',
            unit: 'g/dL',
            reference: ReferenceRange.none(),
            value: 15.1,
          ),
        ],
      );
    }

    test('correggere il valore aggiorna la serie storica', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await saveTwo(patientId);

      var table = await series.loadTable(patientId);
      final sbagliata =
          table.series.firstWhere((s) => s.displayName == 'Ematocrito');
      expect(sbagliata.points.single.value, 472);

      await series.updateMeasurementValue(
        measurementId: sbagliata.points.single.measurementId,
        value: 47.2,
      );

      table = await series.loadTable(patientId);
      final corretta =
          table.series.firstWhere((s) => s.displayName == 'Ematocrito');
      expect(corretta.points.single.value, 47.2);
      expect(corretta.points.single.refLow, 40,
          reason: 'il riferimento del referto originale non va perso');
    });

    test('il valore corretto risulta rivisto', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      await saveTwo(patientId);
      final table = await series.loadTable(patientId);
      final punto = table.series
          .firstWhere((s) => s.displayName == 'Ematocrito')
          .points
          .single;

      await series.updateMeasurementValue(
        measurementId: punto.measurementId,
        value: 47.2,
      );

      final row = await (db.select(db.measurements)
            ..where((m) => m.id.equals(punto.measurementId)))
          .getSingle();
      expect(row.reviewed, isTrue,
          reason: 'distingue un valore corretto a mano da uno accettato '
              'così come estratto');
    });

    test('eliminare una misura lascia intatte le altre del referto', () async {
      final patientId = await patients.create(fullName: 'Paziente Prova');
      final reportId = await saveTwo(patientId);

      var table = await series.loadTable(patientId);
      final punto = table.series
          .firstWhere((s) => s.displayName == 'Ematocrito')
          .points
          .single;

      await series.deleteMeasurement(punto.measurementId);

      table = await series.loadTable(patientId);
      expect(
        table.series.where((s) => s.displayName == 'Ematocrito'),
        isEmpty,
      );
      expect(
        table.series.where((s) => s.displayName == 'Emoglobina'),
        hasLength(1),
        reason: 'si elimina una misura, non il referto',
      );
      expect(await reports.measurementsOf(reportId), hasLength(1));
    });
  });
}
