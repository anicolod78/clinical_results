/// Modelli di dominio prodotti dal parser dei referti.
///
/// Nessuna dipendenza da Flutter: questo strato è puro Dart e testabile
/// senza binding, così il parser può essere verificato sui referti reali.
library;

/// Tipo di intervallo di riferimento stampato sul referto.
enum ReferenceKind {
  /// `4.0 - 10.0` oppure `(150−400)`
  range,

  /// `<15`, `(<= 14.9)`
  upperBound,

  /// `>40`
  lowerBound,

  /// `Valore desiderabile: <190`
  desirableUpper,

  /// `Valore desiderabile: >40`
  desirableLower,

  /// Nessun riferimento stampato (es. eGFR).
  none,
}

/// Intervallo di riferimento normalizzato.
class ReferenceRange {
  const ReferenceRange({
    required this.kind,
    required this.raw,
    this.low,
    this.high,
  });

  const ReferenceRange.none() : kind = ReferenceKind.none, raw = '', low = null, high = null;

  final ReferenceKind kind;

  /// Testo originale, mostrato all'utente in revisione così può verificare
  /// che l'interpretazione automatica corrisponda al referto.
  final String raw;

  final double? low;
  final double? high;

  bool get isEmpty => kind == ReferenceKind.none;

  /// Un riferimento "desiderabile" è un obiettivo clinico, non un intervallo
  /// di normalità di laboratorio: va mostrato ma non usato per marcare
  /// il valore come patologico.
  bool get isDesirable =>
      kind == ReferenceKind.desirableUpper || kind == ReferenceKind.desirableLower;

  /// Etichetta leggibile ricostruita dai bound (per la tabella).
  String get label {
    switch (kind) {
      case ReferenceKind.range:
        return '${_fmt(low)} - ${_fmt(high)}';
      case ReferenceKind.upperBound:
        return '< ${_fmt(high)}';
      case ReferenceKind.lowerBound:
        return '> ${_fmt(low)}';
      case ReferenceKind.desirableUpper:
        return 'desiderabile < ${_fmt(high)}';
      case ReferenceKind.desirableLower:
        return 'desiderabile > ${_fmt(low)}';
      case ReferenceKind.none:
        return '';
    }
  }

  static String _fmt(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble() && v.abs() < 1000000) return v.toStringAsFixed(0);
    return v.toString();
  }

  @override
  String toString() => 'ReferenceRange(${kind.name}, low: $low, high: $high, raw: "$raw")';
}

/// Posizione del valore rispetto al riferimento.
enum ValueFlag { normal, low, high, unknown }

/// Un singolo analita estratto dal referto.
class ParsedAnalyte {
  const ParsedAnalyte({
    required this.rawName,
    required this.canonicalKey,
    required this.displayName,
    required this.unit,
    required this.reference,
    this.value,
    this.rawValue,
    this.section,
    this.panel,
    this.note,
    this.sourceLine = -1,
  });

  /// Nome così come stampato (matrice inclusa: `S-Colesterolo`).
  final String rawName;

  /// Chiave di confronto nel tempo: nome canonico + unità normalizzata.
  ///
  /// L'unità fa parte della chiave perché sui referti reali lo stesso nome
  /// compare con unità diverse (es. `Neutrofili` in `%` e in `x10^9/L`):
  /// unirli produrrebbe un grafico privo di senso clinico.
  final String canonicalKey;

  /// Nome pulito da mostrare in tabella e in legenda.
  final String displayName;

  /// Valore numerico, se interpretabile.
  final double? value;

  /// Testo del valore quando non è numerico (`assente`, `tracce`, `negativo`).
  final String? rawValue;

  /// Unità normalizzata (`x10^9/L`, `mg/dL`, `%`, ...).
  final String unit;

  final ReferenceRange reference;

  /// Sezione del referto (`EMATOLOGIA`, `CHIMICA CLINICA`, ...).
  final String? section;

  /// Pannello (`Emocromo`, `Formula leucocitaria`, ...).
  final String? panel;

  /// Nota testuale associata dal laboratorio.
  final String? note;

  /// Riga del testo normalizzato da cui proviene, per la revisione manuale.
  final int sourceLine;

  /// Posizione rispetto al riferimento.
  ///
  /// I riferimenti "desiderabili" non marcano il valore come patologico:
  /// sono obiettivi, non limiti di normalità.
  ValueFlag get flag {
    final v = value;
    if (v == null || reference.isEmpty || reference.isDesirable) return ValueFlag.unknown;
    final low = reference.low;
    final high = reference.high;
    if (low != null && v < low) return ValueFlag.low;
    if (high != null && v > high) return ValueFlag.high;
    return ValueFlag.normal;
  }

  ParsedAnalyte copyWith({
    String? displayName,
    double? value,
    String? unit,
    ReferenceRange? reference,
    String? note,
  }) {
    return ParsedAnalyte(
      rawName: rawName,
      canonicalKey: canonicalKey,
      displayName: displayName ?? this.displayName,
      value: value ?? this.value,
      rawValue: rawValue,
      unit: unit ?? this.unit,
      reference: reference ?? this.reference,
      section: section,
      panel: panel,
      note: note ?? this.note,
      sourceLine: sourceLine,
    );
  }

  @override
  String toString() =>
      '$displayName = $value $unit [${reference.label}] (${flag.name})';
}

/// Anagrafica letta dall'intestazione del referto.
class ParsedPatient {
  const ParsedPatient({this.fiscalCode, this.fullName, this.birthDate, this.sex});

  final String? fiscalCode;
  final String? fullName;
  final DateTime? birthDate;
  final String? sex;

  bool get isEmpty => fiscalCode == null && fullName == null;

  @override
  String toString() => 'ParsedPatient($fullName, $fiscalCode, $birthDate, $sex)';
}

/// Una data trovata nel documento, con la sua provenienza.
///
/// Il parser non sceglie in silenzio: espone tutte le candidate così che la
/// schermata di revisione possa mostrarle e l'utente confermare.
class DateCandidate {
  const DateCandidate({
    required this.date,
    required this.label,
    required this.priority,
  });

  final DateTime date;

  /// Etichetta di provenienza (`Prelievo del`, `Prodotto il`, `nome file`...).
  final String label;

  /// Più basso = più attendibile come data del prelievo.
  final int priority;

  @override
  String toString() => '$label: ${date.day}/${date.month}/${date.year} (p$priority)';
}

/// Esito completo dell'analisi di un referto.
class ParsedReport {
  const ParsedReport({
    required this.patient,
    required this.analytes,
    required this.dateCandidates,
    required this.warnings,
    required this.rawText,
    this.examDate,
    this.examDateLabel,
    this.laboratory,
    this.reportNumber,
  });

  final ParsedPatient patient;
  final List<ParsedAnalyte> analytes;

  /// Data del prelievo scelta automaticamente, se individuata.
  final DateTime? examDate;

  /// Provenienza della data scelta, mostrata in revisione.
  final String? examDateLabel;

  final List<DateCandidate> dateCandidates;
  final String? laboratory;
  final String? reportNumber;

  /// Anomalie incontrate: righe non interpretate, riferimenti assenti, ecc.
  final List<String> warnings;

  final String rawText;

  /// Quando è `true` la UI deve obbligare l'utente a digitare la data.
  bool get requiresManualDate => examDate == null;

  @override
  String toString() =>
      'ParsedReport(${analytes.length} analiti, data: $examDate [$examDateLabel], '
      '${warnings.length} avvisi)';
}
