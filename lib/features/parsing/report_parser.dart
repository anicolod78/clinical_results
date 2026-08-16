/// Analisi di un referto di laboratorio in forma testuale.
///
/// Il testo può provenire dal livello testo di un PDF oppure dall'OCR di una
/// foto: il parser lavora solo su stringhe, così la stessa logica serve
/// entrambe le origini ed è verificabile con test puri.
///
/// L'approccio è una macchina a stati riga per riga, non un'unica espressione
/// regolare, perché i referti reali distribuiscono nome, valore, unità e
/// intervallo su una sola riga oppure su tre righe consecutive a seconda
/// della versione del software di laboratorio.
///
/// Il risultato non è mai considerato definitivo: la UI di revisione mostra
/// ogni valore accanto al testo originale e richiede conferma prima del
/// salvataggio. Su dati sanitari un'estrazione automatica silenziosa sarebbe
/// inaccettabile.
library;

import 'analyte_catalog.dart';
import 'models.dart';
import 'text_normalizer.dart';

class ReportParser {
  const ReportParser();

  // --- Riconoscimento struttura ---

  /// Riga di intestazione della tabella: da qui in poi ci sono gli esami.
  static final _tableHeader = RegExp(
    r'^esame\s+(valore|risultato)\b',
    caseSensitive: false,
  );

  /// Sezioni note dei referti italiani.
  static const _sections = <String>[
    'EMATOLOGIA',
    'CHIMICA CLINICA',
    'BIOCHIMICA CLINICA',
    'IMMUNOLOGIA',
    'IMMUNOMETRIA',
    'MICROBIOLOGIA',
    'SIEROLOGIA',
    'COAGULAZIONE',
    'EMOSTASI',
    'ORMONI',
    'MARCATORI TUMORALI',
    'TOSSICOLOGIA',
    'URINE',
    'ESAME URINE',
  ];

  /// Righe di servizio del referto, da ignorare sempre.
  static final _noise = <RegExp>[
    RegExp(r'^pag(ina)?\.?\s*\d+\s*(di|/)\s*\d+', caseSensitive: false),
    RegExp(r'firmato digitalmente', caseSensitive: false),
    RegExp(r'^referto\b', caseSensitive: false),
    RegExp(r'richiesta\s*n', caseSensitive: false),
    RegExp(r'^richiedente', caseSensitive: false),
    RegExp(r'data di nascita', caseSensitive: false),
    RegExp(r'^cod\.?\s*fiscale', caseSensitive: false),
    RegExp(r'^prodotto il', caseSensitive: false),
    RegExp(r'^prelievo del', caseSensitive: false),
    RegExp(r'^codice nosologico', caseSensitive: false),
    RegExp(r'^direttore', caseSensitive: false),
    RegExp(r'^ospedale', caseSensitive: false),
    RegExp(r'^-+$'),
  ];

  /// Righe di commento del laboratorio, associate all'esame precedente.
  static final _noteStart = RegExp(
    r'^(valore decisionale|nota\b|n\.b\.|commento|metodo\b|si consiglia|alterata\b)',
    caseSensitive: false,
  );

  // --- Riconoscimento dati ---

  /// Nome incollato al valore: `Leucociti5.0`, `Piastrine180`, `MCV92.2`.
  ///
  /// Il nome è pigro e deve terminare con un carattere "da nome", così il
  /// motore si ferma esattamente al confine testo/numero.
  /// Il `%` chiude il nome perché alcuni referti distinguono così le due
  /// misure della formula leucocitaria (`Neutrofili %` accanto a
  /// `Neutrofili assoluti`). Senza, il motore proseguirebbe fino al punto
  /// decimale del valore e leggerebbe `64.7` come `7`.
  static final _analyteLine = RegExp(
    r'^(?<name>.*?[A-Za-zÀ-ÿ)\].%])\s*(?<value>\d+(?:[.,]\d+)?)\s*(?<rest>.*)$',
  );

  /// Riga che inizia con il valore: il nome sta sulla riga precedente.
  ///
  /// La coda è facoltativa. Nel testo estratto da un PDF il valore porta con
  /// sé unità e intervallo, ma il riconoscimento ottico separa le colonne
  /// della tabella e il valore finisce spesso da solo sulla propria riga:
  /// pretendere che segua dell'altro farebbe perdere la misura.
  static final _valueFirstLine = RegExp(
    r'^(?<value>[<>]?=?\s*\d+(?:[.,]\d+)?)\s*(?<rest>.*)$',
  );

  /// Numerazione di pagina o contatore di servizio.
  ///
  /// Va riconosciuta solo quando non si sta aspettando un valore: altrimenti
  /// un risultato intero come `187` per le piastrine verrebbe scartato
  /// scambiandolo per un piè di pagina.
  static final _standaloneNumber = RegExp(r'^\d{1,3}$');

  /// Valore non numerico: `Assente`, `Negativo`, `Tracce`.
  static final _qualitativeLine = RegExp(
    r'^(?<name>.+?)\s*[:\s]\s*(?<value>assente|presente|negativo|positivo|tracce|nella norma)\s*$',
    caseSensitive: false,
  );

  static final _pureUnit = RegExp(
    r'^(%|x10\^\d{1,2}/[a-zA-Z]+|[a-zA-Zµ]{1,6}(/[a-zA-Z0-9µ,\.]{1,8}){0,3})$',
  );

  static final _pureReference = RegExp(
    r'^\(?\s*(([<>]=?\s*[\d.,]+)|([\d.,]+\s*-\s*[\d.,]+))\s*\)?$',
  );

  /// Data in formato italiano.
  ///
  /// I confini usano `(?<!\d)`/`(?!\d)` e non `\b`: nei PDF il testo estratto
  /// incolla la data alla parola successiva (`23/12/2024ora: 09:56`,
  /// `10/3/1978Data di Nascita:`) e fra `4` e `o` non esiste confine di parola.
  static final _dateRe = RegExp(r'(?<!\d)(\d{1,2})[/.](\d{1,2})[/.](\d{4})(?!\d)');
  static final _fiscalCodeRe = RegExp(r'\b([A-Z]{6}\d{2}[A-Z]\d{2}[A-Z]\d{3}[A-Z])\b');
  static final _isoDateInName = RegExp(r'(\d{4})[-_.](\d{2})[-_.](\d{2})');

  /// Parole che escludono una riga maiuscola dall'essere un nome di persona.
  static const _institutional = <String>[
    'AZIENDA', 'DIPARTIMENTO', 'LABORATORIO', 'OSPEDALE', 'PROVINCIALE',
    'SERVIZI', 'SANITARI', 'SANITARIA', 'PATOLOGIA', 'CLINICA', 'EMATOLOGIA',
    'CHIMICA', 'TRENTO', 'DIRETTORE', 'REFERTO', 'ESAME', 'RISULTATO',
    'MEDAGLIE', 'LARGO', 'VIA', 'PIAZZA', 'CENTRO', 'EMONET', 'UNIVERSITARIA',
    'INTEGRATA', 'TRENTINO', 'DOTT', 'U.O.M', 'SANTA', 'CHIARA', 'FORMULA',
    'LEUCOCITARIA', 'EMOCROMO', 'BIOCHIMICA',
  ];

  /// Analizza il testo di un referto.
  ///
  /// [fileName] è opzionale ma utile: molti referti scaricati dal fascicolo
  /// sanitario hanno la data nel nome del file, che diventa una candidata in
  /// più quando l'intestazione è illeggibile.
  ParsedReport parse(String rawText, {String? fileName}) {
    final text = TextNormalizer.normalize(rawText);
    final lines = text.split('\n');
    final warnings = <String>[];

    final patient = _parsePatient(lines);
    final dates = _collectDates(lines, patient.birthDate, fileName);
    final chosen = _chooseDate(dates);
    final analytes = _parseAnalytes(lines, warnings);

    if (analytes.isEmpty) {
      warnings.add(
        'Nessun esame riconosciuto: verificare la qualità del documento '
        'e inserire i valori manualmente.',
      );
    }
    if (chosen == null) {
      warnings.add('Data del prelievo non trovata: va inserita manualmente.');
    }

    return ParsedReport(
      patient: patient,
      analytes: analytes,
      examDate: chosen?.date,
      examDateLabel: chosen?.label,
      dateCandidates: dates,
      laboratory: _parseLaboratory(lines),
      reportNumber: _firstMatch(text, RegExp(r'Referto:\s*(\d+)')),
      warnings: warnings,
      rawText: text,
    );
  }

  // ------------------------------------------------------------------
  // Intestazione
  // ------------------------------------------------------------------

  ParsedPatient _parsePatient(List<String> lines) {
    final joined = lines.join('\n');
    final fiscalCode = _fiscalCodeRe.firstMatch(joined)?.group(1);

    DateTime? birthDate;
    String? sex;
    for (final line in lines) {
      if (line.toLowerCase().contains('data di nascita')) {
        final m = _dateRe.firstMatch(line);
        if (m != null) birthDate = _toDate(m);
      }
      final s = RegExp(r'Sesso:?\s*([MF])\b').firstMatch(line);
      if (s != null) sex = s.group(1);
    }
    // Layout 2019: "Sesso:" e il valore finiscono su righe separate.
    if (sex == null) {
      final idx = lines.indexWhere((l) => l.toLowerCase().startsWith('sesso'));
      if (idx >= 0) {
        for (var i = idx + 1; i < lines.length && i < idx + 8; i++) {
          if (RegExp(r'^[MF]$').hasMatch(lines[i])) {
            sex = lines[i];
            break;
          }
        }
      }
    }

    return ParsedPatient(
      fiscalCode: fiscalCode,
      fullName: _parseFullName(lines),
      birthDate: birthDate,
      sex: sex,
    );
  }

  String? _parseFullName(List<String> lines) {
    final limit = _tableStartIndex(lines);
    for (var i = 0; i < (limit < 0 ? lines.length : limit); i++) {
      final line = lines[i].trim();
      if (line.length < 5 || line.length > 45) continue;
      if (!RegExp(r"^[A-ZÀ-Ü][A-ZÀ-Ü' ]+$").hasMatch(line)) continue;
      final words = line.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.length < 2 || words.length > 4) continue;
      if (words.any((w) => _institutional.contains(w))) continue;
      return line;
    }
    return null;
  }

  String? _parseLaboratory(List<String> lines) {
    for (final line in lines) {
      if (line.trim().length > 10) return line.trim();
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Date
  // ------------------------------------------------------------------

  /// Raccoglie tutte le date plausibili con la loro provenienza.
  ///
  /// La data che interessa clinicamente è quella del **prelievo**, non quella
  /// di produzione del referto: possono differire di giorni e usare la seconda
  /// sfalserebbe l'asse temporale dei grafici.
  List<DateCandidate> _collectDates(
    List<String> lines,
    DateTime? birthDate,
    String? fileName,
  ) {
    final out = <DateCandidate>[];
    final seen = <String>{};

    void add(DateTime d, String label, int priority) {
      if (birthDate != null && _sameDay(d, birthDate)) return;
      if (d.year < 1900 || d.year > 2200) return;
      final key = '${d.toIso8601String()}|$label';
      if (!seen.add(key)) return;
      out.add(DateCandidate(date: d, label: label, priority: priority));
    }

    for (final line in lines) {
      final lower = line.toLowerCase();
      final matches = _dateRe.allMatches(line).toList();
      if (matches.isEmpty) continue;

      if (lower.contains('prelievo del')) {
        add(_toDate(matches.first), 'Prelievo', 0);
        continue;
      }
      if (lower.contains('data:')) {
        add(_toDate(matches.first), 'Data richiesta', 1);
        continue;
      }
      if (lower.contains('prodotto il')) {
        add(_toDate(matches.first), 'Produzione referto', 3);
        continue;
      }
      if (lower.contains('data di nascita')) continue;
      for (final m in matches) {
        add(_toDate(m), 'Data nel documento', 4);
      }
    }

    if (fileName != null) {
      final m = _isoDateInName.firstMatch(fileName);
      if (m != null) {
        add(
          DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!)),
          'Nome del file',
          2,
        );
      }
    }

    return out;
  }

  /// Sceglie la candidata più attendibile: prima per provenienza, poi la più
  /// antica, perché il prelievo precede sempre la stampa del referto.
  DateCandidate? _chooseDate(List<DateCandidate> candidates) {
    if (candidates.isEmpty) return null;
    final sorted = [...candidates]..sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      return p != 0 ? p : a.date.compareTo(b.date);
    });
    return sorted.first;
  }

  // ------------------------------------------------------------------
  // Corpo della tabella
  // ------------------------------------------------------------------

  int _tableStartIndex(List<String> lines) =>
      lines.indexWhere((l) => _tableHeader.hasMatch(l.trim()));

  List<ParsedAnalyte> _parseAnalytes(List<String> lines, List<String> warnings) {
    final out = <ParsedAnalyte>[];
    final start = _tableStartIndex(lines);
    // Se manca l'intestazione (tipico dell'OCR di una foto) si analizza tutto,
    // affidandosi ai filtri di rumore.
    var i = start >= 0 ? start + 1 : 0;

    String? section;
    String? panel;
    String? pendingName;
    _Pending? pending;

    void flush() {
      if (pending == null) return;
      out.add(pending!.build(section, panel));
      pending = null;
    }

    while (i < lines.length) {
      var line = lines[i].trim();
      i++;

      if (line.isEmpty) continue;
      if (_tableHeader.hasMatch(line)) continue;
      if (_noise.any((r) => r.hasMatch(line))) continue;

      // Un numero isolato è un piè di pagina solo se non c'è un esame in
      // attesa del proprio valore.
      if (pending == null &&
          pendingName == null &&
          _standaloneNumber.hasMatch(line)) {
        continue;
      }

      // Nome spezzato su più righe da una parentesi rimasta aperta.
      if (_hasOpenParen(line) && !RegExp(r'\d').hasMatch(line)) {
        var joins = 0;
        while (i < lines.length && _hasOpenParen(line) && joins < 2) {
          line = '$line ${lines[i].trim()}';
          i++;
          joins++;
        }
      }

      // Sezione, eventualmente incollata al primo esame che la segue.
      final sec = _matchSection(line);
      if (sec != null) {
        flush();
        section = sec.name;
        panel = null;
        pendingName = null;
        if (sec.remainder.isEmpty) continue;
        line = sec.remainder;
      }

      // Unità su riga propria (layout 2019).
      if (pending != null && pending!.unit.isEmpty && _isPureUnit(line)) {
        pending!.unit = line;
        continue;
      }
      // Intervallo su riga propria (layout 2019).
      if (pending != null && pending!.reference == null && _isPureReference(line)) {
        pending!.reference = _parseReference(line);
        flush();
        continue;
      }
      // Coda di un'unità andata a capo, es. "mL/min/1,73" + "mq".
      if (pending != null &&
          pending!.unit.isNotEmpty &&
          RegExp(r'^[a-z]{1,6}$').hasMatch(line)) {
        pending!.unit = '${pending!.unit} $line';
        continue;
      }

      if (_noteStart.hasMatch(line)) {
        if (pending != null) {
          pending!.note = line;
        } else if (out.isNotEmpty) {
          out[out.length - 1] = out.last.copyWith(note: line);
        }
        continue;
      }

      // Esame completo sulla stessa riga.
      final m = _analyteLine.firstMatch(line);
      if (m != null && _isPlausibleName(m.namedGroup('name')!)) {
        flush();
        pendingName = null;
        pending = _Pending(
          rawName: m.namedGroup('name')!.trim(),
          value: TextNormalizer.parseNumber(m.namedGroup('value')!),
          sourceLine: i - 1,
        );
        _applyRest(pending!, m.namedGroup('rest')!);
        if (pending!.reference != null) flush();
        continue;
      }

      // Riga che inizia col valore: il nome è quello messo da parte.
      final v = _valueFirstLine.firstMatch(line);
      if (v != null && pendingName != null) {
        flush();
        pending = _Pending(
          rawName: pendingName,
          value: TextNormalizer.parseNumber(v.namedGroup('value')!),
          sourceLine: i - 1,
        );
        _applyRest(pending!, v.namedGroup('rest')!);
        pendingName = null;
        if (pending!.reference != null) flush();
        continue;
      }

      // Esito qualitativo (`Emoglobinuria: assente`).
      final q = _qualitativeLine.firstMatch(line);
      if (q != null && _isPlausibleName(q.namedGroup('name')!)) {
        flush();
        final name = q.namedGroup('name')!.trim();
        out.add(ParsedAnalyte(
          rawName: name,
          canonicalKey: AnalyteCatalog.keyFor(name, ''),
          displayName: AnalyteCatalog.displayNameFor(name),
          unit: '',
          reference: const ReferenceRange.none(),
          rawValue: q.namedGroup('value'),
          section: section,
          panel: panel,
          sourceLine: i - 1,
        ));
        continue;
      }

      // Riga senza numeri: o è un titolo di pannello, o è il nome di un esame
      // il cui valore sta sulla riga successiva. Decide la riga seguente.
      if (!RegExp(r'\d').hasMatch(line)) {
        flush();
        if (_nextLineStartsWithValue(lines, i)) {
          pendingName = line;
        } else {
          panel = line;
          pendingName = null;
        }
        continue;
      }

      warnings.add('Riga non interpretata (${i - 1}): $line');
    }

    flush();
    return out;
  }

  bool _nextLineStartsWithValue(List<String> lines, int from) {
    for (var j = from; j < lines.length && j < from + 3; j++) {
      final l = lines[j].trim();
      if (l.isEmpty) continue;
      if (_noise.any((r) => r.hasMatch(l))) continue;
      return _valueFirstLine.hasMatch(l) && !_isPureReference(l);
    }
    return false;
  }

  /// Separa unità e intervallo nella coda della riga dell'esame.
  ///
  /// L'ordine delle colonne non è lo stesso in tutti i referti: alcuni
  /// stampano `valore unità intervallo`, altri `valore intervallo unità`.
  /// Invece di assumere una disposizione si individua l'intervallo ovunque si
  /// trovi, e quel che resta prima e dopo è l'unità di misura.
  void _applyRest(_Pending p, String rest) {
    final trimmed = rest.trim();
    if (trimmed.isEmpty) return;

    final reference = _findReference(trimmed);
    if (reference == null) {
      p.unit = _cleanUnit(trimmed);
      return;
    }

    p.reference = _parseReference(reference.text);
    p.unit = _cleanUnit(
      '${trimmed.substring(0, reference.start)} '
      '${trimmed.substring(reference.end)}',
    );
  }

  /// Cerca l'intervallo di riferimento nella coda della riga.
  ///
  /// La ricerca segue una precedenza per tipo e non per posizione: un
  /// intervallo `3 - 10` vince su una soglia `> 3` anche quando la soglia
  /// compare prima. Serve perché alcuni referti antepongono un simbolo di
  /// fuori norma al riferimento vero e proprio (`> 3 - 10 %`), e leggerlo
  /// come soglia darebbe un riferimento sbagliato.
  ({String text, int start, int end})? _findReference(String rest) {
    for (final pattern in [_desirableRe, _rangeRe, _boundRe]) {
      final m = pattern.firstMatch(rest);
      if (m != null) {
        return (text: m[0]!, start: m.start, end: m.end);
      }
    }

    // Ultima risorsa: due numeri separati dal solo spazio.
    //
    // Il riconoscimento ottico perde con facilità il trattino sottile fra i
    // due estremi, e `13.5 - 18` arriva come `13.5 18`. Senza questo
    // recupero l'intervallo verrebbe scambiato per unità di misura e il
    // valore resterebbe senza riferimento. Si accetta solo quando il primo
    // numero non supera il secondo, altrimenti non è un intervallo.
    final loose = _looseRangeRe.firstMatch(rest);
    if (loose != null) {
      final low = TextNormalizer.parseNumber(loose[1]!);
      final high = TextNormalizer.parseNumber(loose[2]!);
      if (low != null && high != null && low <= high) {
        return (text: loose[0]!, start: loose.start, end: loose.end);
      }
    }
    return null;
  }

  static final _desirableRe = RegExp(
    r'valore\s+desiderabil\w*\s*:?\s*[<>]=?\s*[\d]+(?:[.,]\d+)?',
    caseSensitive: false,
  );

  static final _rangeRe = RegExp(
    r'\(?\s*[\d]+(?:[.,]\d+)?\s*-\s*[\d]+(?:[.,]\d+)?\s*\)?',
  );

  static final _boundRe = RegExp(
    r'\(?\s*[<>]=?\s*[\d]+(?:[.,]\d+)?\s*\)?',
  );

  /// Due numeri interi o decimali separati solo da spazi, ciascuno isolato:
  /// i controlli ai lati evitano di spezzare un numero più lungo o di
  /// agganciare le cifre contenute in un'unità come `mL/min/1,73`.
  static final _looseRangeRe = RegExp(
    r'(?<![\d.,])(\d+(?:[.,]\d+)?)\s+(\d+(?:[.,]\d+)?)(?![\d.,])',
  );

  /// Ripulisce l'unità dai residui lasciati dal riconoscimento ottico.
  ///
  /// Toglie i simboli di fuori norma rimasti isolati, la punteggiatura in
  /// coda, e soprattutto le cifre iniziali: quando l'OCR sgrana un estremo
  /// dell'intervallo, parte del numero può restare attaccata all'unità
  /// (`0.4x10^9/L`, `4%`). Se passasse, la chiave della serie storica
  /// cambierebbe e il valore non si unirebbe agli altri dello stesso esame.
  ///
  /// L'unica unità che inizia legittimamente con una cifra non esiste: le
  /// potenze si scrivono `x10^9/L`, quindi con una lettera.
  String _cleanUnit(String raw) {
    var unit = raw
        .replaceAll(RegExp(r'[<>]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    unit = unit.replaceFirst(RegExp(r'^[\d.,]+\s*(?=[a-zA-Zµ%])'), '');
    unit = unit.replaceFirst(RegExp(r'[.,;:]+$'), '');
    return unit.trim();
  }

  ReferenceRange _parseReference(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const ReferenceRange.none();

    final desirable = RegExp(
      r'desiderabil\w*\s*:?\s*([<>]=?)\s*([\d.,]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (desirable != null) {
      final n = TextNormalizer.parseNumber(desirable.group(2)!);
      final isUpper = desirable.group(1)!.startsWith('<');
      return ReferenceRange(
        kind: isUpper ? ReferenceKind.desirableUpper : ReferenceKind.desirableLower,
        raw: text,
        low: isUpper ? null : n,
        high: isUpper ? n : null,
      );
    }

    // Il separatore può essere il trattino oppure, quando il riconoscimento
    // ottico lo ha perso, il solo spazio.
    final range =
        RegExp(r'([\d]+(?:[.,]\d+)?)\s*(?:-|\s)\s*([\d]+(?:[.,]\d+)?)')
            .firstMatch(text);
    if (range != null) {
      return ReferenceRange(
        kind: ReferenceKind.range,
        raw: text,
        low: TextNormalizer.parseNumber(range.group(1)!),
        high: TextNormalizer.parseNumber(range.group(2)!),
      );
    }

    final bound = RegExp(r'([<>])=?\s*([\d]+(?:[.,]\d+)?)').firstMatch(text);
    if (bound != null) {
      final n = TextNormalizer.parseNumber(bound.group(2)!);
      final isUpper = bound.group(1) == '<';
      return ReferenceRange(
        kind: isUpper ? ReferenceKind.upperBound : ReferenceKind.lowerBound,
        raw: text,
        low: isUpper ? null : n,
        high: isUpper ? n : null,
      );
    }

    return ReferenceRange(kind: ReferenceKind.none, raw: text);
  }

  // ------------------------------------------------------------------
  // Utilità di classificazione
  // ------------------------------------------------------------------

  ({String name, String remainder})? _matchSection(String line) {
    final cleaned = line.replaceAll(RegExp(r'^[\s-]+|[\s-]+$'), '').trim();
    final upper = cleaned.toUpperCase();
    for (final s in _sections) {
      if (upper == s) return (name: s, remainder: '');
      // Sezione incollata al primo esame: `CHIMICA CLINICAS-Colesterolo`.
      if (upper.startsWith(s)) {
        return (name: s, remainder: cleaned.substring(s.length).trim());
      }
    }
    return null;
  }

  bool _isPureUnit(String line) => _pureUnit.hasMatch(line.trim());

  bool _isPureReference(String line) => _pureReference.hasMatch(line.trim());

  /// Un nome di esame è breve: filtra le frasi di commento che altrimenti
  /// verrebbero scambiate per esami (contengono numeri e sembrano righe dati).
  bool _isPlausibleName(String name) {
    final n = name.trim();
    if (n.isEmpty || n.length > 45) return false;
    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(n)) return false;
    final words = n.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return words <= 6;
  }

  bool _hasOpenParen(String line) {
    final open = '('.allMatches(line).length;
    final close = ')'.allMatches(line).length;
    return open > close;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _toDate(RegExpMatch m) =>
      DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));

  static String? _firstMatch(String text, RegExp re) => re.firstMatch(text)?.group(1);
}

/// Accumulatore mutabile per un esame in corso di composizione.
class _Pending {
  _Pending({required this.rawName, required this.value, required this.sourceLine});

  final String rawName;
  final double? value;
  final int sourceLine;
  String unit = '';
  ReferenceRange? reference;
  String? note;

  /// Ricava l'unità dal nome quando la colonna non è stata letta.
  ///
  /// Nei referti che distinguono `Neutrofili %` da `Neutrofili assoluti` il
  /// nome dichiara già la misura. Se il riconoscimento ottico perde il `%`
  /// della colonna dell'unità, ricavarlo dal nome evita che la stessa misura
  /// si divida in due serie: una con l'unità e una senza.
  ///
  /// Vale solo per la percentuale, l'unica desumibile dal nome senza
  /// ipotesi: "assoluti" non dice in quale scala.
  String _unitOrElseFromName() {
    if (unit.isNotEmpty) return unit;
    return rawName.trimRight().endsWith('%') ? '%' : unit;
  }

  ParsedAnalyte build(String? section, String? panel) {
    final normalizedUnit = AnalyteCatalog.resolveUnit(
      rawName,
      TextNormalizer.normalizeUnit(_unitOrElseFromName()),
    );
    return ParsedAnalyte(
      rawName: rawName,
      canonicalKey: AnalyteCatalog.keyFor(rawName, normalizedUnit),
      displayName: AnalyteCatalog.displayNameFor(rawName),
      value: value,
      unit: normalizedUnit,
      reference: reference ?? const ReferenceRange.none(),
      section: section,
      panel: panel,
      note: note,
      sourceLine: sourceLine,
    );
  }
}
