/// Catalogo degli analiti e riconduzione dei nomi a una forma canonica.
///
/// Serve a rendere confrontabili nel tempo referti prodotti da laboratori e
/// da versioni di software diversi, dove lo stesso esame cambia nome
/// (`B-VES` / `S-VES` / `VES`, `Proteina C reattiva` / `PCR`).
library;

import 'text_normalizer.dart';

/// Voce del catalogo: nome canonico, sinonimi e raggruppamento.
class AnalyteDefinition {
  const AnalyteDefinition({
    required this.canonicalName,
    required this.displayName,
    required this.synonyms,
    this.group = 'Altro',
    this.preferredUnit,
  });

  /// Chiave interna, minuscola e senza accenti.
  final String canonicalName;

  /// Nome mostrato all'utente.
  final String displayName;

  /// Varianti riscontrabili sui referti, già in forma normalizzata.
  final List<String> synonyms;

  /// Raggruppamento per la navigazione (Emocromo, Lipidi, Fegato...).
  final String group;

  final String? preferredUnit;
}

/// Prefissi di matrice biologica usati dai laboratori italiani.
///
/// `B-` sangue intero, `S-` siero, `P-` plasma, `Sg-` sangue, `U-` urine.
/// Vanno rimossi per il confronto ma conservati nel dato grezzo, perché lo
/// stesso analita misurato su matrici diverse resta clinicamente lo stesso
/// andamento agli occhi dell'utente.
final _matrixPrefix = RegExp(r'^(b|s|sg|p|pl|u|er|dU|fS)\s*-\s*', caseSensitive: false);

/// Note di metodo fra parentesi, da togliere dal nome.
final _methodNote = RegExp(r'\((?:[^()]*)\)\s*$');

final _accents = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

class AnalyteCatalog {
  const AnalyteCatalog._();

  static const definitions = <AnalyteDefinition>[
    // --- Emocromo ---
    AnalyteDefinition(
      canonicalName: 'leucociti',
      displayName: 'Leucociti',
      synonyms: ['globuli bianchi', 'wbc', 'gb'],
      group: 'Emocromo',
      preferredUnit: 'x10^9/L',
    ),
    AnalyteDefinition(
      canonicalName: 'eritrociti',
      displayName: 'Eritrociti',
      synonyms: ['globuli rossi', 'rbc', 'gr'],
      group: 'Emocromo',
      preferredUnit: 'x10^12/L',
    ),
    AnalyteDefinition(
      canonicalName: 'emoglobina',
      displayName: 'Emoglobina',
      synonyms: ['hb', 'hgb'],
      group: 'Emocromo',
      preferredUnit: 'g/dL',
    ),
    AnalyteDefinition(
      canonicalName: 'ematocrito',
      displayName: 'Ematocrito',
      synonyms: ['hct', 'ht'],
      group: 'Emocromo',
      preferredUnit: '%',
    ),
    // I referti alternano sigle e denominazioni per esteso: senza i sinonimi
    // lo stesso esame formerebbe due serie storiche separate a seconda di
    // come il laboratorio lo ha stampato.
    AnalyteDefinition(
      canonicalName: 'mcv',
      displayName: 'MCV',
      synonyms: ['volume corpuscolare medio', 'volume cellulare medio'],
      group: 'Emocromo',
      preferredUnit: 'fL',
    ),
    AnalyteDefinition(
      canonicalName: 'mch',
      displayName: 'MCH',
      synonyms: ['emoglobina corpuscolare media', 'contenuto emoglobinico medio'],
      group: 'Emocromo',
      preferredUnit: 'pg',
    ),
    AnalyteDefinition(
      canonicalName: 'mchc',
      displayName: 'MCHC',
      synonyms: [
        'concentrazione emoglobinica corpuscolare',
        'concentrazione emoglobinica corpuscolare media',
      ],
      group: 'Emocromo',
      preferredUnit: 'g/dL',
    ),
    AnalyteDefinition(
      canonicalName: 'rdw',
      displayName: 'RDW',
      synonyms: [
        'rdw cv',
        'indice di anisocitosi corpuscolare',
        'ampiezza di distribuzione eritrocitaria',
      ],
      group: 'Emocromo',
      preferredUnit: '%',
    ),
    AnalyteDefinition(
      canonicalName: 'piastrine',
      displayName: 'Piastrine',
      synonyms: ['plt', 'trombociti'],
      group: 'Emocromo',
      preferredUnit: 'x10^9/L',
    ),
    AnalyteDefinition(canonicalName: 'mpv', displayName: 'MPV', synonyms: [], group: 'Emocromo', preferredUnit: 'fL'),

    // --- Formula leucocitaria ---
    //
    // I suffissi "assoluti" e "%" indicano quale delle due misure si sta
    // leggendo, ma a distinguerle è già l'unità nella chiave di serie: qui
    // vanno ricondotti allo stesso analita, altrimenti il valore assoluto
    // letto da una foto non si unirebbe a quello letto da un PDF.
    AnalyteDefinition(
      canonicalName: 'neutrofili',
      displayName: 'Neutrofili',
      synonyms: ['granulociti neutrofili', 'neutrofili assoluti'],
      group: 'Formula leucocitaria',
    ),
    AnalyteDefinition(
      canonicalName: 'linfociti',
      displayName: 'Linfociti',
      synonyms: ['linfociti assoluti'],
      group: 'Formula leucocitaria',
    ),
    AnalyteDefinition(
      canonicalName: 'monociti',
      displayName: 'Monociti',
      synonyms: ['monociti assoluti'],
      group: 'Formula leucocitaria',
    ),
    AnalyteDefinition(
      canonicalName: 'eosinofili',
      displayName: 'Eosinofili',
      synonyms: ['granulociti eosinofili', 'eosinofili assoluti'],
      group: 'Formula leucocitaria',
    ),
    AnalyteDefinition(
      canonicalName: 'basofili',
      displayName: 'Basofili',
      synonyms: ['granulociti basofili', 'basofili assoluti'],
      group: 'Formula leucocitaria',
    ),

    // --- Infiammazione ---
    AnalyteDefinition(
      canonicalName: 'ves',
      displayName: 'VES',
      synonyms: ['velocita di eritrosedimentazione', 'vg'],
      group: 'Infiammazione',
      preferredUnit: 'mm/h',
    ),
    AnalyteDefinition(
      canonicalName: 'proteina c reattiva',
      displayName: 'Proteina C reattiva (PCR)',
      synonyms: ['pcr', 'proteina c-reattiva', 'crp'],
      group: 'Infiammazione',
      preferredUnit: 'mg/L',
    ),

    // --- Lipidi ---
    AnalyteDefinition(canonicalName: 'colesterolo', displayName: 'Colesterolo totale', synonyms: ['colesterolo totale'], group: 'Lipidi', preferredUnit: 'mg/dL'),
    AnalyteDefinition(canonicalName: 'colesterolo hdl', displayName: 'Colesterolo HDL', synonyms: ['hdl'], group: 'Lipidi', preferredUnit: 'mg/dL'),
    AnalyteDefinition(canonicalName: 'colesterolo ldl', displayName: 'Colesterolo LDL', synonyms: ['ldl'], group: 'Lipidi', preferredUnit: 'mg/dL'),
    AnalyteDefinition(canonicalName: 'trigliceridi', displayName: 'Trigliceridi', synonyms: [], group: 'Lipidi', preferredUnit: 'mg/dL'),

    // --- Fegato ---
    AnalyteDefinition(canonicalName: 'alt', displayName: 'ALT (GPT)', synonyms: ['alt alan amino transf', 'gpt', 'alanina aminotransferasi', 'transaminasi gpt'], group: 'Fegato', preferredUnit: 'U/L'),
    AnalyteDefinition(canonicalName: 'ast', displayName: 'AST (GOT)', synonyms: ['ast asp amino transf', 'got', 'aspartato aminotransferasi', 'transaminasi got'], group: 'Fegato', preferredUnit: 'U/L'),
    AnalyteDefinition(canonicalName: 'ggt', displayName: 'Gamma GT', synonyms: ['gamma gt', 'gamma-gt', 'y-gt'], group: 'Fegato', preferredUnit: 'U/L'),
    AnalyteDefinition(canonicalName: 'bilirubina totale', displayName: 'Bilirubina totale', synonyms: ['bilirubina'], group: 'Fegato', preferredUnit: 'mg/dL'),
    AnalyteDefinition(canonicalName: 'fosfatasi alcalina', displayName: 'Fosfatasi alcalina', synonyms: ['alp'], group: 'Fegato', preferredUnit: 'U/L'),

    // --- Rene / metabolismo ---
    AnalyteDefinition(canonicalName: 'creatinina', displayName: 'Creatinina', synonyms: [], group: 'Rene', preferredUnit: 'mg/dL'),
    AnalyteDefinition(canonicalName: 'egfr', displayName: 'eGFR (filtrato glomerulare)', synonyms: ['egfr stima filtrato glomerulare', 'filtrato glomerulare', 'vfg'], group: 'Rene'),
    AnalyteDefinition(canonicalName: 'azotemia', displayName: 'Azotemia (urea)', synonyms: ['urea', 'bun'], group: 'Rene', preferredUnit: 'mg/dL'),
    AnalyteDefinition(canonicalName: 'glucosio', displayName: 'Glucosio (glicemia)', synonyms: ['glicemia'], group: 'Metabolismo', preferredUnit: 'mg/dL'),
    AnalyteDefinition(canonicalName: 'emoglobina glicata', displayName: 'Emoglobina glicata (HbA1c)', synonyms: ['hba1c', 'glicata'], group: 'Metabolismo', preferredUnit: 'mmol/mol'),
    AnalyteDefinition(canonicalName: 'acido urico', displayName: 'Acido urico', synonyms: ['uricemia'], group: 'Metabolismo', preferredUnit: 'mg/dL'),
    AnalyteDefinition(canonicalName: 'proteine totali', displayName: 'Proteine totali', synonyms: [], group: 'Metabolismo', preferredUnit: 'g/L'),

    // --- Tiroide ---
    AnalyteDefinition(canonicalName: 'tsh', displayName: 'TSH', synonyms: ['tsh reflex'], group: 'Tiroide'),
    AnalyteDefinition(canonicalName: 'ft3', displayName: 'FT3', synonyms: ['triiodotironina libera'], group: 'Tiroide'),
    AnalyteDefinition(canonicalName: 'ft4', displayName: 'FT4', synonyms: ['tiroxina libera'], group: 'Tiroide'),

    // --- Marziale / vitamine ---
    AnalyteDefinition(canonicalName: 'ferro', displayName: 'Ferro (sideremia)', synonyms: ['sideremia'], group: 'Marziale'),
    AnalyteDefinition(canonicalName: 'ferritina', displayName: 'Ferritina', synonyms: [], group: 'Marziale'),
    AnalyteDefinition(canonicalName: 'transferrina', displayName: 'Transferrina', synonyms: [], group: 'Marziale'),
    AnalyteDefinition(canonicalName: 'vitamina d', displayName: 'Vitamina D (25-OH)', synonyms: ['25-oh vitamina d', 'vitamina d 25 oh', 'colecalciferolo'], group: 'Vitamine'),
    AnalyteDefinition(canonicalName: 'vitamina b12', displayName: 'Vitamina B12', synonyms: ['b12', 'cobalamina'], group: 'Vitamine'),
    AnalyteDefinition(canonicalName: 'folati', displayName: 'Folati', synonyms: ['acido folico'], group: 'Vitamine'),

    // --- Elettroliti ---
    AnalyteDefinition(canonicalName: 'sodio', displayName: 'Sodio', synonyms: ['na'], group: 'Elettroliti'),
    AnalyteDefinition(canonicalName: 'potassio', displayName: 'Potassio', synonyms: ['k'], group: 'Elettroliti'),
    AnalyteDefinition(canonicalName: 'calcio', displayName: 'Calcio', synonyms: ['ca'], group: 'Elettroliti'),
  ];

  static final Map<String, AnalyteDefinition> _index = _buildIndex();

  static Map<String, AnalyteDefinition> _buildIndex() {
    final map = <String, AnalyteDefinition>{};
    for (final d in definitions) {
      map[d.canonicalName] = d;
      for (final s in d.synonyms) {
        map[s] = d;
      }
    }
    return map;
  }

  /// Riduce un nome stampato alla sua forma confrontabile.
  ///
  /// Toglie prefisso di matrice, note di metodo, punteggiatura e accenti.
  static String normalizeName(String rawName) {
    var n = rawName.trim();
    n = n.replaceAll(_methodNote, '').trim();
    // Parentesi rimasta aperta per un a capo del PDF: `S-eGFR ... Glomerulare(`
    n = n.replaceAll(RegExp(r'\($'), '').trim();
    n = n.replaceFirst(_matrixPrefix, '');
    n = n.toLowerCase();
    final buffer = StringBuffer();
    for (final ch in n.split('')) {
      buffer.write(_accents[ch] ?? ch);
    }
    n = buffer.toString();
    n = n.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
    return n;
  }

  /// Trova la definizione del catalogo, se l'analita è noto.
  static AnalyteDefinition? lookup(String rawName) => _index[normalizeName(rawName)];

  /// Nome da mostrare: quello del catalogo se noto, altrimenti il nome
  /// stampato ripulito dal prefisso di matrice.
  static String displayNameFor(String rawName) {
    final def = lookup(rawName);
    if (def != null) return def.displayName;
    var n = rawName.trim().replaceAll(_methodNote, '').trim();
    n = n.replaceAll(RegExp(r'\($'), '').trim();
    n = n.replaceFirst(_matrixPrefix, '');
    return n.isEmpty ? rawName.trim() : n;
  }

  static String groupFor(String rawName) => lookup(rawName)?.group ?? 'Altro';

  /// Ripara un'unità troncata dal riconoscimento ottico.
  ///
  /// Sui referti fotografati capita che si perda una lettera finale: `fL`
  /// letto come `f`, `g/dL` come `g`. Il danno non è estetico — l'unità entra
  /// nella chiave della serie storica, quindi lo stesso esame si spezza in due
  /// curve, una per la lettura buona e una per quella monca.
  ///
  /// Si interviene solo quando l'unità letta è un troncamento di quella attesa
  /// per quell'analita. Un'unità semplicemente diversa viene lasciata stare:
  /// potrebbe essere un laboratorio che misura davvero in un'altra scala, e
  /// sostituirla significherebbe alterare il dato. Un'unità assente non viene
  /// riempita, per lo stesso motivo.
  static String resolveUnit(String rawName, String unit) {
    final preferred = lookup(rawName)?.preferredUnit;
    if (preferred == null || unit.isEmpty || unit == preferred) return unit;

    final read = unit.toLowerCase();
    final expected = preferred.toLowerCase();
    final isTruncation =
        expected.startsWith(read) || read.startsWith(expected);
    return isTruncation ? preferred : unit;
  }

  /// Chiave di serie storica.
  ///
  /// Include l'unità di proposito: `Neutrofili %` e `Neutrofili x10^9/L`
  /// sono due misure diverse dello stesso elemento e vanno graficate a parte.
  static String keyFor(String rawName, String unit) {
    final def = lookup(rawName);
    final base = def?.canonicalName ?? normalizeName(rawName);
    final u = TextNormalizer.normalizeUnit(unit);
    return u.isEmpty ? base : '$base|$u';
  }
}
