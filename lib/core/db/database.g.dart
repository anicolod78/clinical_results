// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PatientsTable extends Patients with TableInfo<$PatientsTable, Patient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiscalCodeMeta = const VerificationMeta(
    'fiscalCode',
  );
  @override
  late final GeneratedColumn<String> fiscalCode = GeneratedColumn<String>(
    'fiscal_code',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 16),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fullName,
    fiscalCode,
    birthDate,
    sex,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Patient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('fiscal_code')) {
      context.handle(
        _fiscalCodeMeta,
        fiscalCode.isAcceptableOrUnknown(data['fiscal_code']!, _fiscalCodeMeta),
      );
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Patient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Patient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      fiscalCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_code'],
      ),
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class Patient extends DataClass implements Insertable<Patient> {
  final int id;
  final String fullName;

  /// Permette di riconoscere automaticamente il paziente all'importazione:
  /// i referti italiani riportano quasi sempre il codice fiscale.
  final String? fiscalCode;
  final DateTime? birthDate;
  final String? sex;
  final String? note;
  final DateTime createdAt;
  const Patient({
    required this.id,
    required this.fullName,
    this.fiscalCode,
    this.birthDate,
    this.sex,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || fiscalCode != null) {
      map['fiscal_code'] = Variable<String>(fiscalCode);
    }
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PatientsCompanion toCompanion(bool nullToAbsent) {
    return PatientsCompanion(
      id: Value(id),
      fullName: Value(fullName),
      fiscalCode: fiscalCode == null && nullToAbsent
          ? const Value.absent()
          : Value(fiscalCode),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Patient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Patient(
      id: serializer.fromJson<int>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      fiscalCode: serializer.fromJson<String?>(json['fiscalCode']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      sex: serializer.fromJson<String?>(json['sex']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fullName': serializer.toJson<String>(fullName),
      'fiscalCode': serializer.toJson<String?>(fiscalCode),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'sex': serializer.toJson<String?>(sex),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Patient copyWith({
    int? id,
    String? fullName,
    Value<String?> fiscalCode = const Value.absent(),
    Value<DateTime?> birthDate = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => Patient(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    fiscalCode: fiscalCode.present ? fiscalCode.value : this.fiscalCode,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    sex: sex.present ? sex.value : this.sex,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  Patient copyWithCompanion(PatientsCompanion data) {
    return Patient(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      fiscalCode: data.fiscalCode.present
          ? data.fiscalCode.value
          : this.fiscalCode,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      sex: data.sex.present ? data.sex.value : this.sex,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Patient(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('fiscalCode: $fiscalCode, ')
          ..write('birthDate: $birthDate, ')
          ..write('sex: $sex, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fullName, fiscalCode, birthDate, sex, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Patient &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.fiscalCode == this.fiscalCode &&
          other.birthDate == this.birthDate &&
          other.sex == this.sex &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class PatientsCompanion extends UpdateCompanion<Patient> {
  final Value<int> id;
  final Value<String> fullName;
  final Value<String?> fiscalCode;
  final Value<DateTime?> birthDate;
  final Value<String?> sex;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const PatientsCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.fiscalCode = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.sex = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PatientsCompanion.insert({
    this.id = const Value.absent(),
    required String fullName,
    this.fiscalCode = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.sex = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : fullName = Value(fullName);
  static Insertable<Patient> custom({
    Expression<int>? id,
    Expression<String>? fullName,
    Expression<String>? fiscalCode,
    Expression<DateTime>? birthDate,
    Expression<String>? sex,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (fiscalCode != null) 'fiscal_code': fiscalCode,
      if (birthDate != null) 'birth_date': birthDate,
      if (sex != null) 'sex': sex,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PatientsCompanion copyWith({
    Value<int>? id,
    Value<String>? fullName,
    Value<String?>? fiscalCode,
    Value<DateTime?>? birthDate,
    Value<String?>? sex,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return PatientsCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      fiscalCode: fiscalCode ?? this.fiscalCode,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (fiscalCode.present) {
      map['fiscal_code'] = Variable<String>(fiscalCode.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientsCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('fiscalCode: $fiscalCode, ')
          ..write('birthDate: $birthDate, ')
          ..write('sex: $sex, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReportsTable extends Reports with TableInfo<$ReportsTable, Report> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _examDateMeta = const VerificationMeta(
    'examDate',
  );
  @override
  late final GeneratedColumn<DateTime> examDate = GeneratedColumn<DateTime>(
    'exam_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _laboratoryMeta = const VerificationMeta(
    'laboratory',
  );
  @override
  late final GeneratedColumn<String> laboratory = GeneratedColumn<String>(
    'laboratory',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportNumberMeta = const VerificationMeta(
    'reportNumber',
  );
  @override
  late final GeneratedColumn<String> reportNumber = GeneratedColumn<String>(
    'report_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceKind, String> sourceKind =
      GeneratedColumn<String>(
        'source_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SourceKind>($ReportsTable.$convertersourceKind);
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalDocumentMeta = const VerificationMeta(
    'originalDocument',
  );
  @override
  late final GeneratedColumn<Uint8List> originalDocument =
      GeneratedColumn<Uint8List>(
        'original_document',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    examDate,
    importedAt,
    laboratory,
    reportNumber,
    sourceKind,
    sourceName,
    originalDocument,
    rawText,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Report> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('exam_date')) {
      context.handle(
        _examDateMeta,
        examDate.isAcceptableOrUnknown(data['exam_date']!, _examDateMeta),
      );
    } else if (isInserting) {
      context.missing(_examDateMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    }
    if (data.containsKey('laboratory')) {
      context.handle(
        _laboratoryMeta,
        laboratory.isAcceptableOrUnknown(data['laboratory']!, _laboratoryMeta),
      );
    }
    if (data.containsKey('report_number')) {
      context.handle(
        _reportNumberMeta,
        reportNumber.isAcceptableOrUnknown(
          data['report_number']!,
          _reportNumberMeta,
        ),
      );
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    }
    if (data.containsKey('original_document')) {
      context.handle(
        _originalDocumentMeta,
        originalDocument.isAcceptableOrUnknown(
          data['original_document']!,
          _originalDocumentMeta,
        ),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Report map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Report(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}patient_id'],
      )!,
      examDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}exam_date'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      laboratory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}laboratory'],
      ),
      reportNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_number'],
      ),
      sourceKind: $ReportsTable.$convertersourceKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_kind'],
        )!,
      ),
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      ),
      originalDocument: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}original_document'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $ReportsTable createAlias(String alias) {
    return $ReportsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceKind, String, String> $convertersourceKind =
      const EnumNameConverter<SourceKind>(SourceKind.values);
}

class Report extends DataClass implements Insertable<Report> {
  final int id;
  final int patientId;

  /// Data del prelievo: è l'asse temporale di tabelle e grafici.
  final DateTime examDate;
  final DateTime importedAt;
  final String? laboratory;
  final String? reportNumber;
  final SourceKind sourceKind;
  final String? sourceName;

  /// Documento originale conservato dentro il database, quindi cifrato come
  /// tutto il resto: tenerlo come file separato lo lascerebbe in chiaro nella
  /// memoria del dispositivo.
  final Uint8List? originalDocument;

  /// Testo estratto, utile per rivedere l'origine di un valore.
  final String? rawText;
  final String? note;
  const Report({
    required this.id,
    required this.patientId,
    required this.examDate,
    required this.importedAt,
    this.laboratory,
    this.reportNumber,
    required this.sourceKind,
    this.sourceName,
    this.originalDocument,
    this.rawText,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['patient_id'] = Variable<int>(patientId);
    map['exam_date'] = Variable<DateTime>(examDate);
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || laboratory != null) {
      map['laboratory'] = Variable<String>(laboratory);
    }
    if (!nullToAbsent || reportNumber != null) {
      map['report_number'] = Variable<String>(reportNumber);
    }
    {
      map['source_kind'] = Variable<String>(
        $ReportsTable.$convertersourceKind.toSql(sourceKind),
      );
    }
    if (!nullToAbsent || sourceName != null) {
      map['source_name'] = Variable<String>(sourceName);
    }
    if (!nullToAbsent || originalDocument != null) {
      map['original_document'] = Variable<Uint8List>(originalDocument);
    }
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  ReportsCompanion toCompanion(bool nullToAbsent) {
    return ReportsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      examDate: Value(examDate),
      importedAt: Value(importedAt),
      laboratory: laboratory == null && nullToAbsent
          ? const Value.absent()
          : Value(laboratory),
      reportNumber: reportNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(reportNumber),
      sourceKind: Value(sourceKind),
      sourceName: sourceName == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceName),
      originalDocument: originalDocument == null && nullToAbsent
          ? const Value.absent()
          : Value(originalDocument),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Report.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Report(
      id: serializer.fromJson<int>(json['id']),
      patientId: serializer.fromJson<int>(json['patientId']),
      examDate: serializer.fromJson<DateTime>(json['examDate']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      laboratory: serializer.fromJson<String?>(json['laboratory']),
      reportNumber: serializer.fromJson<String?>(json['reportNumber']),
      sourceKind: $ReportsTable.$convertersourceKind.fromJson(
        serializer.fromJson<String>(json['sourceKind']),
      ),
      sourceName: serializer.fromJson<String?>(json['sourceName']),
      originalDocument: serializer.fromJson<Uint8List?>(
        json['originalDocument'],
      ),
      rawText: serializer.fromJson<String?>(json['rawText']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientId': serializer.toJson<int>(patientId),
      'examDate': serializer.toJson<DateTime>(examDate),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'laboratory': serializer.toJson<String?>(laboratory),
      'reportNumber': serializer.toJson<String?>(reportNumber),
      'sourceKind': serializer.toJson<String>(
        $ReportsTable.$convertersourceKind.toJson(sourceKind),
      ),
      'sourceName': serializer.toJson<String?>(sourceName),
      'originalDocument': serializer.toJson<Uint8List?>(originalDocument),
      'rawText': serializer.toJson<String?>(rawText),
      'note': serializer.toJson<String?>(note),
    };
  }

  Report copyWith({
    int? id,
    int? patientId,
    DateTime? examDate,
    DateTime? importedAt,
    Value<String?> laboratory = const Value.absent(),
    Value<String?> reportNumber = const Value.absent(),
    SourceKind? sourceKind,
    Value<String?> sourceName = const Value.absent(),
    Value<Uint8List?> originalDocument = const Value.absent(),
    Value<String?> rawText = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => Report(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    examDate: examDate ?? this.examDate,
    importedAt: importedAt ?? this.importedAt,
    laboratory: laboratory.present ? laboratory.value : this.laboratory,
    reportNumber: reportNumber.present ? reportNumber.value : this.reportNumber,
    sourceKind: sourceKind ?? this.sourceKind,
    sourceName: sourceName.present ? sourceName.value : this.sourceName,
    originalDocument: originalDocument.present
        ? originalDocument.value
        : this.originalDocument,
    rawText: rawText.present ? rawText.value : this.rawText,
    note: note.present ? note.value : this.note,
  );
  Report copyWithCompanion(ReportsCompanion data) {
    return Report(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      examDate: data.examDate.present ? data.examDate.value : this.examDate,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      laboratory: data.laboratory.present
          ? data.laboratory.value
          : this.laboratory,
      reportNumber: data.reportNumber.present
          ? data.reportNumber.value
          : this.reportNumber,
      sourceKind: data.sourceKind.present
          ? data.sourceKind.value
          : this.sourceKind,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      originalDocument: data.originalDocument.present
          ? data.originalDocument.value
          : this.originalDocument,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Report(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('examDate: $examDate, ')
          ..write('importedAt: $importedAt, ')
          ..write('laboratory: $laboratory, ')
          ..write('reportNumber: $reportNumber, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('sourceName: $sourceName, ')
          ..write('originalDocument: $originalDocument, ')
          ..write('rawText: $rawText, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    examDate,
    importedAt,
    laboratory,
    reportNumber,
    sourceKind,
    sourceName,
    $driftBlobEquality.hash(originalDocument),
    rawText,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Report &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.examDate == this.examDate &&
          other.importedAt == this.importedAt &&
          other.laboratory == this.laboratory &&
          other.reportNumber == this.reportNumber &&
          other.sourceKind == this.sourceKind &&
          other.sourceName == this.sourceName &&
          $driftBlobEquality.equals(
            other.originalDocument,
            this.originalDocument,
          ) &&
          other.rawText == this.rawText &&
          other.note == this.note);
}

class ReportsCompanion extends UpdateCompanion<Report> {
  final Value<int> id;
  final Value<int> patientId;
  final Value<DateTime> examDate;
  final Value<DateTime> importedAt;
  final Value<String?> laboratory;
  final Value<String?> reportNumber;
  final Value<SourceKind> sourceKind;
  final Value<String?> sourceName;
  final Value<Uint8List?> originalDocument;
  final Value<String?> rawText;
  final Value<String?> note;
  const ReportsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.examDate = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.laboratory = const Value.absent(),
    this.reportNumber = const Value.absent(),
    this.sourceKind = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.originalDocument = const Value.absent(),
    this.rawText = const Value.absent(),
    this.note = const Value.absent(),
  });
  ReportsCompanion.insert({
    this.id = const Value.absent(),
    required int patientId,
    required DateTime examDate,
    this.importedAt = const Value.absent(),
    this.laboratory = const Value.absent(),
    this.reportNumber = const Value.absent(),
    required SourceKind sourceKind,
    this.sourceName = const Value.absent(),
    this.originalDocument = const Value.absent(),
    this.rawText = const Value.absent(),
    this.note = const Value.absent(),
  }) : patientId = Value(patientId),
       examDate = Value(examDate),
       sourceKind = Value(sourceKind);
  static Insertable<Report> custom({
    Expression<int>? id,
    Expression<int>? patientId,
    Expression<DateTime>? examDate,
    Expression<DateTime>? importedAt,
    Expression<String>? laboratory,
    Expression<String>? reportNumber,
    Expression<String>? sourceKind,
    Expression<String>? sourceName,
    Expression<Uint8List>? originalDocument,
    Expression<String>? rawText,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (examDate != null) 'exam_date': examDate,
      if (importedAt != null) 'imported_at': importedAt,
      if (laboratory != null) 'laboratory': laboratory,
      if (reportNumber != null) 'report_number': reportNumber,
      if (sourceKind != null) 'source_kind': sourceKind,
      if (sourceName != null) 'source_name': sourceName,
      if (originalDocument != null) 'original_document': originalDocument,
      if (rawText != null) 'raw_text': rawText,
      if (note != null) 'note': note,
    });
  }

  ReportsCompanion copyWith({
    Value<int>? id,
    Value<int>? patientId,
    Value<DateTime>? examDate,
    Value<DateTime>? importedAt,
    Value<String?>? laboratory,
    Value<String?>? reportNumber,
    Value<SourceKind>? sourceKind,
    Value<String?>? sourceName,
    Value<Uint8List?>? originalDocument,
    Value<String?>? rawText,
    Value<String?>? note,
  }) {
    return ReportsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      examDate: examDate ?? this.examDate,
      importedAt: importedAt ?? this.importedAt,
      laboratory: laboratory ?? this.laboratory,
      reportNumber: reportNumber ?? this.reportNumber,
      sourceKind: sourceKind ?? this.sourceKind,
      sourceName: sourceName ?? this.sourceName,
      originalDocument: originalDocument ?? this.originalDocument,
      rawText: rawText ?? this.rawText,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (examDate.present) {
      map['exam_date'] = Variable<DateTime>(examDate.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (laboratory.present) {
      map['laboratory'] = Variable<String>(laboratory.value);
    }
    if (reportNumber.present) {
      map['report_number'] = Variable<String>(reportNumber.value);
    }
    if (sourceKind.present) {
      map['source_kind'] = Variable<String>(
        $ReportsTable.$convertersourceKind.toSql(sourceKind.value),
      );
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (originalDocument.present) {
      map['original_document'] = Variable<Uint8List>(originalDocument.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('examDate: $examDate, ')
          ..write('importedAt: $importedAt, ')
          ..write('laboratory: $laboratory, ')
          ..write('reportNumber: $reportNumber, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('sourceName: $sourceName, ')
          ..write('originalDocument: $originalDocument, ')
          ..write('rawText: $rawText, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, Measurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reportIdMeta = const VerificationMeta(
    'reportId',
  );
  @override
  late final GeneratedColumn<int> reportId = GeneratedColumn<int>(
    'report_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reports (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _canonicalKeyMeta = const VerificationMeta(
    'canonicalKey',
  );
  @override
  late final GeneratedColumn<String> canonicalKey = GeneratedColumn<String>(
    'canonical_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawNameMeta = const VerificationMeta(
    'rawName',
  );
  @override
  late final GeneratedColumn<String> rawName = GeneratedColumn<String>(
    'raw_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawValueMeta = const VerificationMeta(
    'rawValue',
  );
  @override
  late final GeneratedColumn<String> rawValue = GeneratedColumn<String>(
    'raw_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _refLowMeta = const VerificationMeta('refLow');
  @override
  late final GeneratedColumn<double> refLow = GeneratedColumn<double>(
    'ref_low',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refHighMeta = const VerificationMeta(
    'refHigh',
  );
  @override
  late final GeneratedColumn<double> refHigh = GeneratedColumn<double>(
    'ref_high',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StoredReferenceKind, String>
  refKind = GeneratedColumn<String>(
    'ref_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(StoredReferenceKind.none.name),
  ).withConverter<StoredReferenceKind>($MeasurementsTable.$converterrefKind);
  static const VerificationMeta _refRawMeta = const VerificationMeta('refRaw');
  @override
  late final GeneratedColumn<String> refRaw = GeneratedColumn<String>(
    'ref_raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _panelMeta = const VerificationMeta('panel');
  @override
  late final GeneratedColumn<String> panel = GeneratedColumn<String>(
    'panel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedMeta = const VerificationMeta(
    'reviewed',
  );
  @override
  late final GeneratedColumn<bool> reviewed = GeneratedColumn<bool>(
    'reviewed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reviewed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reportId,
    patientId,
    canonicalKey,
    displayName,
    rawName,
    value,
    rawValue,
    unit,
    refLow,
    refHigh,
    refKind,
    refRaw,
    section,
    panel,
    note,
    reviewed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Measurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('report_id')) {
      context.handle(
        _reportIdMeta,
        reportId.isAcceptableOrUnknown(data['report_id']!, _reportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reportIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('canonical_key')) {
      context.handle(
        _canonicalKeyMeta,
        canonicalKey.isAcceptableOrUnknown(
          data['canonical_key']!,
          _canonicalKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalKeyMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('raw_name')) {
      context.handle(
        _rawNameMeta,
        rawName.isAcceptableOrUnknown(data['raw_name']!, _rawNameMeta),
      );
    } else if (isInserting) {
      context.missing(_rawNameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('raw_value')) {
      context.handle(
        _rawValueMeta,
        rawValue.isAcceptableOrUnknown(data['raw_value']!, _rawValueMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('ref_low')) {
      context.handle(
        _refLowMeta,
        refLow.isAcceptableOrUnknown(data['ref_low']!, _refLowMeta),
      );
    }
    if (data.containsKey('ref_high')) {
      context.handle(
        _refHighMeta,
        refHigh.isAcceptableOrUnknown(data['ref_high']!, _refHighMeta),
      );
    }
    if (data.containsKey('ref_raw')) {
      context.handle(
        _refRawMeta,
        refRaw.isAcceptableOrUnknown(data['ref_raw']!, _refRawMeta),
      );
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    }
    if (data.containsKey('panel')) {
      context.handle(
        _panelMeta,
        panel.isAcceptableOrUnknown(data['panel']!, _panelMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('reviewed')) {
      context.handle(
        _reviewedMeta,
        reviewed.isAcceptableOrUnknown(data['reviewed']!, _reviewedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Measurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Measurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reportId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}report_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}patient_id'],
      )!,
      canonicalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_key'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      rawName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      rawValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_value'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      refLow: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_low'],
      ),
      refHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_high'],
      ),
      refKind: $MeasurementsTable.$converterrefKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ref_kind'],
        )!,
      ),
      refRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_raw'],
      ),
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      ),
      panel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}panel'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      reviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reviewed'],
      )!,
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StoredReferenceKind, String, String>
  $converterrefKind = const EnumNameConverter<StoredReferenceKind>(
    StoredReferenceKind.values,
  );
}

class Measurement extends DataClass implements Insertable<Measurement> {
  final int id;
  final int reportId;

  /// Ripetuto rispetto al referto per interrogare le serie storiche di un
  /// paziente senza join, che è l'accesso più frequente dell'app.
  final int patientId;

  /// Chiave di confronto nel tempo, comprensiva di unità di misura.
  final String canonicalKey;
  final String displayName;
  final String rawName;
  final double? value;

  /// Esito non numerico (`assente`, `negativo`).
  final String? rawValue;
  final String unit;
  final double? refLow;
  final double? refHigh;
  final StoredReferenceKind refKind;
  final String? refRaw;
  final String? section;
  final String? panel;
  final String? note;

  /// Segna i valori rivisti dall'utente, per distinguerli da quelli
  /// accettati così come estratti.
  final bool reviewed;
  const Measurement({
    required this.id,
    required this.reportId,
    required this.patientId,
    required this.canonicalKey,
    required this.displayName,
    required this.rawName,
    this.value,
    this.rawValue,
    required this.unit,
    this.refLow,
    this.refHigh,
    required this.refKind,
    this.refRaw,
    this.section,
    this.panel,
    this.note,
    required this.reviewed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['report_id'] = Variable<int>(reportId);
    map['patient_id'] = Variable<int>(patientId);
    map['canonical_key'] = Variable<String>(canonicalKey);
    map['display_name'] = Variable<String>(displayName);
    map['raw_name'] = Variable<String>(rawName);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    if (!nullToAbsent || rawValue != null) {
      map['raw_value'] = Variable<String>(rawValue);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || refLow != null) {
      map['ref_low'] = Variable<double>(refLow);
    }
    if (!nullToAbsent || refHigh != null) {
      map['ref_high'] = Variable<double>(refHigh);
    }
    {
      map['ref_kind'] = Variable<String>(
        $MeasurementsTable.$converterrefKind.toSql(refKind),
      );
    }
    if (!nullToAbsent || refRaw != null) {
      map['ref_raw'] = Variable<String>(refRaw);
    }
    if (!nullToAbsent || section != null) {
      map['section'] = Variable<String>(section);
    }
    if (!nullToAbsent || panel != null) {
      map['panel'] = Variable<String>(panel);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['reviewed'] = Variable<bool>(reviewed);
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      reportId: Value(reportId),
      patientId: Value(patientId),
      canonicalKey: Value(canonicalKey),
      displayName: Value(displayName),
      rawName: Value(rawName),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      rawValue: rawValue == null && nullToAbsent
          ? const Value.absent()
          : Value(rawValue),
      unit: Value(unit),
      refLow: refLow == null && nullToAbsent
          ? const Value.absent()
          : Value(refLow),
      refHigh: refHigh == null && nullToAbsent
          ? const Value.absent()
          : Value(refHigh),
      refKind: Value(refKind),
      refRaw: refRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(refRaw),
      section: section == null && nullToAbsent
          ? const Value.absent()
          : Value(section),
      panel: panel == null && nullToAbsent
          ? const Value.absent()
          : Value(panel),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      reviewed: Value(reviewed),
    );
  }

  factory Measurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Measurement(
      id: serializer.fromJson<int>(json['id']),
      reportId: serializer.fromJson<int>(json['reportId']),
      patientId: serializer.fromJson<int>(json['patientId']),
      canonicalKey: serializer.fromJson<String>(json['canonicalKey']),
      displayName: serializer.fromJson<String>(json['displayName']),
      rawName: serializer.fromJson<String>(json['rawName']),
      value: serializer.fromJson<double?>(json['value']),
      rawValue: serializer.fromJson<String?>(json['rawValue']),
      unit: serializer.fromJson<String>(json['unit']),
      refLow: serializer.fromJson<double?>(json['refLow']),
      refHigh: serializer.fromJson<double?>(json['refHigh']),
      refKind: $MeasurementsTable.$converterrefKind.fromJson(
        serializer.fromJson<String>(json['refKind']),
      ),
      refRaw: serializer.fromJson<String?>(json['refRaw']),
      section: serializer.fromJson<String?>(json['section']),
      panel: serializer.fromJson<String?>(json['panel']),
      note: serializer.fromJson<String?>(json['note']),
      reviewed: serializer.fromJson<bool>(json['reviewed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reportId': serializer.toJson<int>(reportId),
      'patientId': serializer.toJson<int>(patientId),
      'canonicalKey': serializer.toJson<String>(canonicalKey),
      'displayName': serializer.toJson<String>(displayName),
      'rawName': serializer.toJson<String>(rawName),
      'value': serializer.toJson<double?>(value),
      'rawValue': serializer.toJson<String?>(rawValue),
      'unit': serializer.toJson<String>(unit),
      'refLow': serializer.toJson<double?>(refLow),
      'refHigh': serializer.toJson<double?>(refHigh),
      'refKind': serializer.toJson<String>(
        $MeasurementsTable.$converterrefKind.toJson(refKind),
      ),
      'refRaw': serializer.toJson<String?>(refRaw),
      'section': serializer.toJson<String?>(section),
      'panel': serializer.toJson<String?>(panel),
      'note': serializer.toJson<String?>(note),
      'reviewed': serializer.toJson<bool>(reviewed),
    };
  }

  Measurement copyWith({
    int? id,
    int? reportId,
    int? patientId,
    String? canonicalKey,
    String? displayName,
    String? rawName,
    Value<double?> value = const Value.absent(),
    Value<String?> rawValue = const Value.absent(),
    String? unit,
    Value<double?> refLow = const Value.absent(),
    Value<double?> refHigh = const Value.absent(),
    StoredReferenceKind? refKind,
    Value<String?> refRaw = const Value.absent(),
    Value<String?> section = const Value.absent(),
    Value<String?> panel = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? reviewed,
  }) => Measurement(
    id: id ?? this.id,
    reportId: reportId ?? this.reportId,
    patientId: patientId ?? this.patientId,
    canonicalKey: canonicalKey ?? this.canonicalKey,
    displayName: displayName ?? this.displayName,
    rawName: rawName ?? this.rawName,
    value: value.present ? value.value : this.value,
    rawValue: rawValue.present ? rawValue.value : this.rawValue,
    unit: unit ?? this.unit,
    refLow: refLow.present ? refLow.value : this.refLow,
    refHigh: refHigh.present ? refHigh.value : this.refHigh,
    refKind: refKind ?? this.refKind,
    refRaw: refRaw.present ? refRaw.value : this.refRaw,
    section: section.present ? section.value : this.section,
    panel: panel.present ? panel.value : this.panel,
    note: note.present ? note.value : this.note,
    reviewed: reviewed ?? this.reviewed,
  );
  Measurement copyWithCompanion(MeasurementsCompanion data) {
    return Measurement(
      id: data.id.present ? data.id.value : this.id,
      reportId: data.reportId.present ? data.reportId.value : this.reportId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      canonicalKey: data.canonicalKey.present
          ? data.canonicalKey.value
          : this.canonicalKey,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      rawName: data.rawName.present ? data.rawName.value : this.rawName,
      value: data.value.present ? data.value.value : this.value,
      rawValue: data.rawValue.present ? data.rawValue.value : this.rawValue,
      unit: data.unit.present ? data.unit.value : this.unit,
      refLow: data.refLow.present ? data.refLow.value : this.refLow,
      refHigh: data.refHigh.present ? data.refHigh.value : this.refHigh,
      refKind: data.refKind.present ? data.refKind.value : this.refKind,
      refRaw: data.refRaw.present ? data.refRaw.value : this.refRaw,
      section: data.section.present ? data.section.value : this.section,
      panel: data.panel.present ? data.panel.value : this.panel,
      note: data.note.present ? data.note.value : this.note,
      reviewed: data.reviewed.present ? data.reviewed.value : this.reviewed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Measurement(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('patientId: $patientId, ')
          ..write('canonicalKey: $canonicalKey, ')
          ..write('displayName: $displayName, ')
          ..write('rawName: $rawName, ')
          ..write('value: $value, ')
          ..write('rawValue: $rawValue, ')
          ..write('unit: $unit, ')
          ..write('refLow: $refLow, ')
          ..write('refHigh: $refHigh, ')
          ..write('refKind: $refKind, ')
          ..write('refRaw: $refRaw, ')
          ..write('section: $section, ')
          ..write('panel: $panel, ')
          ..write('note: $note, ')
          ..write('reviewed: $reviewed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reportId,
    patientId,
    canonicalKey,
    displayName,
    rawName,
    value,
    rawValue,
    unit,
    refLow,
    refHigh,
    refKind,
    refRaw,
    section,
    panel,
    note,
    reviewed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Measurement &&
          other.id == this.id &&
          other.reportId == this.reportId &&
          other.patientId == this.patientId &&
          other.canonicalKey == this.canonicalKey &&
          other.displayName == this.displayName &&
          other.rawName == this.rawName &&
          other.value == this.value &&
          other.rawValue == this.rawValue &&
          other.unit == this.unit &&
          other.refLow == this.refLow &&
          other.refHigh == this.refHigh &&
          other.refKind == this.refKind &&
          other.refRaw == this.refRaw &&
          other.section == this.section &&
          other.panel == this.panel &&
          other.note == this.note &&
          other.reviewed == this.reviewed);
}

class MeasurementsCompanion extends UpdateCompanion<Measurement> {
  final Value<int> id;
  final Value<int> reportId;
  final Value<int> patientId;
  final Value<String> canonicalKey;
  final Value<String> displayName;
  final Value<String> rawName;
  final Value<double?> value;
  final Value<String?> rawValue;
  final Value<String> unit;
  final Value<double?> refLow;
  final Value<double?> refHigh;
  final Value<StoredReferenceKind> refKind;
  final Value<String?> refRaw;
  final Value<String?> section;
  final Value<String?> panel;
  final Value<String?> note;
  final Value<bool> reviewed;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.reportId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.canonicalKey = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rawName = const Value.absent(),
    this.value = const Value.absent(),
    this.rawValue = const Value.absent(),
    this.unit = const Value.absent(),
    this.refLow = const Value.absent(),
    this.refHigh = const Value.absent(),
    this.refKind = const Value.absent(),
    this.refRaw = const Value.absent(),
    this.section = const Value.absent(),
    this.panel = const Value.absent(),
    this.note = const Value.absent(),
    this.reviewed = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required int reportId,
    required int patientId,
    required String canonicalKey,
    required String displayName,
    required String rawName,
    this.value = const Value.absent(),
    this.rawValue = const Value.absent(),
    this.unit = const Value.absent(),
    this.refLow = const Value.absent(),
    this.refHigh = const Value.absent(),
    this.refKind = const Value.absent(),
    this.refRaw = const Value.absent(),
    this.section = const Value.absent(),
    this.panel = const Value.absent(),
    this.note = const Value.absent(),
    this.reviewed = const Value.absent(),
  }) : reportId = Value(reportId),
       patientId = Value(patientId),
       canonicalKey = Value(canonicalKey),
       displayName = Value(displayName),
       rawName = Value(rawName);
  static Insertable<Measurement> custom({
    Expression<int>? id,
    Expression<int>? reportId,
    Expression<int>? patientId,
    Expression<String>? canonicalKey,
    Expression<String>? displayName,
    Expression<String>? rawName,
    Expression<double>? value,
    Expression<String>? rawValue,
    Expression<String>? unit,
    Expression<double>? refLow,
    Expression<double>? refHigh,
    Expression<String>? refKind,
    Expression<String>? refRaw,
    Expression<String>? section,
    Expression<String>? panel,
    Expression<String>? note,
    Expression<bool>? reviewed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reportId != null) 'report_id': reportId,
      if (patientId != null) 'patient_id': patientId,
      if (canonicalKey != null) 'canonical_key': canonicalKey,
      if (displayName != null) 'display_name': displayName,
      if (rawName != null) 'raw_name': rawName,
      if (value != null) 'value': value,
      if (rawValue != null) 'raw_value': rawValue,
      if (unit != null) 'unit': unit,
      if (refLow != null) 'ref_low': refLow,
      if (refHigh != null) 'ref_high': refHigh,
      if (refKind != null) 'ref_kind': refKind,
      if (refRaw != null) 'ref_raw': refRaw,
      if (section != null) 'section': section,
      if (panel != null) 'panel': panel,
      if (note != null) 'note': note,
      if (reviewed != null) 'reviewed': reviewed,
    });
  }

  MeasurementsCompanion copyWith({
    Value<int>? id,
    Value<int>? reportId,
    Value<int>? patientId,
    Value<String>? canonicalKey,
    Value<String>? displayName,
    Value<String>? rawName,
    Value<double?>? value,
    Value<String?>? rawValue,
    Value<String>? unit,
    Value<double?>? refLow,
    Value<double?>? refHigh,
    Value<StoredReferenceKind>? refKind,
    Value<String?>? refRaw,
    Value<String?>? section,
    Value<String?>? panel,
    Value<String?>? note,
    Value<bool>? reviewed,
  }) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      patientId: patientId ?? this.patientId,
      canonicalKey: canonicalKey ?? this.canonicalKey,
      displayName: displayName ?? this.displayName,
      rawName: rawName ?? this.rawName,
      value: value ?? this.value,
      rawValue: rawValue ?? this.rawValue,
      unit: unit ?? this.unit,
      refLow: refLow ?? this.refLow,
      refHigh: refHigh ?? this.refHigh,
      refKind: refKind ?? this.refKind,
      refRaw: refRaw ?? this.refRaw,
      section: section ?? this.section,
      panel: panel ?? this.panel,
      note: note ?? this.note,
      reviewed: reviewed ?? this.reviewed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reportId.present) {
      map['report_id'] = Variable<int>(reportId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (canonicalKey.present) {
      map['canonical_key'] = Variable<String>(canonicalKey.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rawName.present) {
      map['raw_name'] = Variable<String>(rawName.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (rawValue.present) {
      map['raw_value'] = Variable<String>(rawValue.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (refLow.present) {
      map['ref_low'] = Variable<double>(refLow.value);
    }
    if (refHigh.present) {
      map['ref_high'] = Variable<double>(refHigh.value);
    }
    if (refKind.present) {
      map['ref_kind'] = Variable<String>(
        $MeasurementsTable.$converterrefKind.toSql(refKind.value),
      );
    }
    if (refRaw.present) {
      map['ref_raw'] = Variable<String>(refRaw.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (panel.present) {
      map['panel'] = Variable<String>(panel.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (reviewed.present) {
      map['reviewed'] = Variable<bool>(reviewed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('patientId: $patientId, ')
          ..write('canonicalKey: $canonicalKey, ')
          ..write('displayName: $displayName, ')
          ..write('rawName: $rawName, ')
          ..write('value: $value, ')
          ..write('rawValue: $rawValue, ')
          ..write('unit: $unit, ')
          ..write('refLow: $refLow, ')
          ..write('refHigh: $refHigh, ')
          ..write('refKind: $refKind, ')
          ..write('refRaw: $refRaw, ')
          ..write('section: $section, ')
          ..write('panel: $panel, ')
          ..write('note: $note, ')
          ..write('reviewed: $reviewed')
          ..write(')'))
        .toString();
  }
}

class $AnalyteAliasesTable extends AnalyteAliases
    with TableInfo<$AnalyteAliasesTable, AnalyteAlias> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalyteAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromKeyMeta = const VerificationMeta(
    'fromKey',
  );
  @override
  late final GeneratedColumn<String> fromKey = GeneratedColumn<String>(
    'from_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toKeyMeta = const VerificationMeta('toKey');
  @override
  late final GeneratedColumn<String> toKey = GeneratedColumn<String>(
    'to_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromLabelMeta = const VerificationMeta(
    'fromLabel',
  );
  @override
  late final GeneratedColumn<String> fromLabel = GeneratedColumn<String>(
    'from_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toLabelMeta = const VerificationMeta(
    'toLabel',
  );
  @override
  late final GeneratedColumn<String> toLabel = GeneratedColumn<String>(
    'to_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    fromKey,
    toKey,
    fromLabel,
    toLabel,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analyte_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnalyteAlias> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_key')) {
      context.handle(
        _fromKeyMeta,
        fromKey.isAcceptableOrUnknown(data['from_key']!, _fromKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fromKeyMeta);
    }
    if (data.containsKey('to_key')) {
      context.handle(
        _toKeyMeta,
        toKey.isAcceptableOrUnknown(data['to_key']!, _toKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_toKeyMeta);
    }
    if (data.containsKey('from_label')) {
      context.handle(
        _fromLabelMeta,
        fromLabel.isAcceptableOrUnknown(data['from_label']!, _fromLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_fromLabelMeta);
    }
    if (data.containsKey('to_label')) {
      context.handle(
        _toLabelMeta,
        toLabel.isAcceptableOrUnknown(data['to_label']!, _toLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_toLabelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fromKey};
  @override
  AnalyteAlias map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalyteAlias(
      fromKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_key'],
      )!,
      toKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_key'],
      )!,
      fromLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_label'],
      )!,
      toLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_label'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnalyteAliasesTable createAlias(String alias) {
    return $AnalyteAliasesTable(attachedDatabase, alias);
  }
}

class AnalyteAlias extends DataClass implements Insertable<AnalyteAlias> {
  /// Chiave da assorbire.
  final String fromKey;

  /// Chiave in cui confluisce.
  final String toKey;

  /// Nome mostrato al momento dell'unione, per poterla descrivere in
  /// elenco senza dover ricostruire la serie.
  final String fromLabel;
  final String toLabel;
  final DateTime createdAt;
  const AnalyteAlias({
    required this.fromKey,
    required this.toKey,
    required this.fromLabel,
    required this.toLabel,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_key'] = Variable<String>(fromKey);
    map['to_key'] = Variable<String>(toKey);
    map['from_label'] = Variable<String>(fromLabel);
    map['to_label'] = Variable<String>(toLabel);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnalyteAliasesCompanion toCompanion(bool nullToAbsent) {
    return AnalyteAliasesCompanion(
      fromKey: Value(fromKey),
      toKey: Value(toKey),
      fromLabel: Value(fromLabel),
      toLabel: Value(toLabel),
      createdAt: Value(createdAt),
    );
  }

  factory AnalyteAlias.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalyteAlias(
      fromKey: serializer.fromJson<String>(json['fromKey']),
      toKey: serializer.fromJson<String>(json['toKey']),
      fromLabel: serializer.fromJson<String>(json['fromLabel']),
      toLabel: serializer.fromJson<String>(json['toLabel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromKey': serializer.toJson<String>(fromKey),
      'toKey': serializer.toJson<String>(toKey),
      'fromLabel': serializer.toJson<String>(fromLabel),
      'toLabel': serializer.toJson<String>(toLabel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnalyteAlias copyWith({
    String? fromKey,
    String? toKey,
    String? fromLabel,
    String? toLabel,
    DateTime? createdAt,
  }) => AnalyteAlias(
    fromKey: fromKey ?? this.fromKey,
    toKey: toKey ?? this.toKey,
    fromLabel: fromLabel ?? this.fromLabel,
    toLabel: toLabel ?? this.toLabel,
    createdAt: createdAt ?? this.createdAt,
  );
  AnalyteAlias copyWithCompanion(AnalyteAliasesCompanion data) {
    return AnalyteAlias(
      fromKey: data.fromKey.present ? data.fromKey.value : this.fromKey,
      toKey: data.toKey.present ? data.toKey.value : this.toKey,
      fromLabel: data.fromLabel.present ? data.fromLabel.value : this.fromLabel,
      toLabel: data.toLabel.present ? data.toLabel.value : this.toLabel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalyteAlias(')
          ..write('fromKey: $fromKey, ')
          ..write('toKey: $toKey, ')
          ..write('fromLabel: $fromLabel, ')
          ..write('toLabel: $toLabel, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(fromKey, toKey, fromLabel, toLabel, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalyteAlias &&
          other.fromKey == this.fromKey &&
          other.toKey == this.toKey &&
          other.fromLabel == this.fromLabel &&
          other.toLabel == this.toLabel &&
          other.createdAt == this.createdAt);
}

class AnalyteAliasesCompanion extends UpdateCompanion<AnalyteAlias> {
  final Value<String> fromKey;
  final Value<String> toKey;
  final Value<String> fromLabel;
  final Value<String> toLabel;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AnalyteAliasesCompanion({
    this.fromKey = const Value.absent(),
    this.toKey = const Value.absent(),
    this.fromLabel = const Value.absent(),
    this.toLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalyteAliasesCompanion.insert({
    required String fromKey,
    required String toKey,
    required String fromLabel,
    required String toLabel,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fromKey = Value(fromKey),
       toKey = Value(toKey),
       fromLabel = Value(fromLabel),
       toLabel = Value(toLabel);
  static Insertable<AnalyteAlias> custom({
    Expression<String>? fromKey,
    Expression<String>? toKey,
    Expression<String>? fromLabel,
    Expression<String>? toLabel,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromKey != null) 'from_key': fromKey,
      if (toKey != null) 'to_key': toKey,
      if (fromLabel != null) 'from_label': fromLabel,
      if (toLabel != null) 'to_label': toLabel,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalyteAliasesCompanion copyWith({
    Value<String>? fromKey,
    Value<String>? toKey,
    Value<String>? fromLabel,
    Value<String>? toLabel,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AnalyteAliasesCompanion(
      fromKey: fromKey ?? this.fromKey,
      toKey: toKey ?? this.toKey,
      fromLabel: fromLabel ?? this.fromLabel,
      toLabel: toLabel ?? this.toLabel,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromKey.present) {
      map['from_key'] = Variable<String>(fromKey.value);
    }
    if (toKey.present) {
      map['to_key'] = Variable<String>(toKey.value);
    }
    if (fromLabel.present) {
      map['from_label'] = Variable<String>(fromLabel.value);
    }
    if (toLabel.present) {
      map['to_label'] = Variable<String>(toLabel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalyteAliasesCompanion(')
          ..write('fromKey: $fromKey, ')
          ..write('toKey: $toKey, ')
          ..write('fromLabel: $fromLabel, ')
          ..write('toLabel: $toLabel, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PatientsTable patients = $PatientsTable(this);
  late final $ReportsTable reports = $ReportsTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $AnalyteAliasesTable analyteAliases = $AnalyteAliasesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    patients,
    reports,
    measurements,
    analyteAliases,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reports', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'reports',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('measurements', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('measurements', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PatientsTableCreateCompanionBuilder =
    PatientsCompanion Function({
      Value<int> id,
      required String fullName,
      Value<String?> fiscalCode,
      Value<DateTime?> birthDate,
      Value<String?> sex,
      Value<String?> note,
      Value<DateTime> createdAt,
    });
typedef $$PatientsTableUpdateCompanionBuilder =
    PatientsCompanion Function({
      Value<int> id,
      Value<String> fullName,
      Value<String?> fiscalCode,
      Value<DateTime?> birthDate,
      Value<String?> sex,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

final class $$PatientsTableReferences
    extends BaseReferences<_$AppDatabase, $PatientsTable, Patient> {
  $$PatientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReportsTable, List<Report>> _reportsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.reports,
    aliasName: 'patients__id__reports__patient_id',
  );

  $$ReportsTableProcessedTableManager get reportsRefs {
    final manager = $$ReportsTableTableManager(
      $_db,
      $_db.reports,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reportsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MeasurementsTable, List<Measurement>>
  _measurementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.measurements,
    aliasName: 'patients__id__measurements__patient_id',
  );

  $$MeasurementsTableProcessedTableManager get measurementsRefs {
    final manager = $$MeasurementsTableTableManager(
      $_db,
      $_db.measurements,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_measurementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PatientsTableFilterComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fiscalCode => $composableBuilder(
    column: $table.fiscalCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reportsRefs(
    Expression<bool> Function($$ReportsTableFilterComposer f) f,
  ) {
    final $$ReportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reports,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportsTableFilterComposer(
            $db: $db,
            $table: $db.reports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> measurementsRefs(
    Expression<bool> Function($$MeasurementsTableFilterComposer f) f,
  ) {
    final $$MeasurementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurements,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementsTableFilterComposer(
            $db: $db,
            $table: $db.measurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PatientsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiscalCode => $composableBuilder(
    column: $table.fiscalCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get fiscalCode => $composableBuilder(
    column: $table.fiscalCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> reportsRefs<T extends Object>(
    Expression<T> Function($$ReportsTableAnnotationComposer a) f,
  ) {
    final $$ReportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reports,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportsTableAnnotationComposer(
            $db: $db,
            $table: $db.reports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> measurementsRefs<T extends Object>(
    Expression<T> Function($$MeasurementsTableAnnotationComposer a) f,
  ) {
    final $$MeasurementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurements,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementsTableAnnotationComposer(
            $db: $db,
            $table: $db.measurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PatientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatientsTable,
          Patient,
          $$PatientsTableFilterComposer,
          $$PatientsTableOrderingComposer,
          $$PatientsTableAnnotationComposer,
          $$PatientsTableCreateCompanionBuilder,
          $$PatientsTableUpdateCompanionBuilder,
          (Patient, $$PatientsTableReferences),
          Patient,
          PrefetchHooks Function({bool reportsRefs, bool measurementsRefs})
        > {
  $$PatientsTableTableManager(_$AppDatabase db, $PatientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> fiscalCode = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PatientsCompanion(
                id: id,
                fullName: fullName,
                fiscalCode: fiscalCode,
                birthDate: birthDate,
                sex: sex,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fullName,
                Value<String?> fiscalCode = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PatientsCompanion.insert(
                id: id,
                fullName: fullName,
                fiscalCode: fiscalCode,
                birthDate: birthDate,
                sex: sex,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PatientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({reportsRefs = false, measurementsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reportsRefs) db.reports,
                    if (measurementsRefs) db.measurements,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reportsRefs)
                        await $_getPrefetchedData<
                          Patient,
                          $PatientsTable,
                          Report
                        >(
                          currentTable: table,
                          referencedTable: $$PatientsTableReferences
                              ._reportsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).reportsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (measurementsRefs)
                        await $_getPrefetchedData<
                          Patient,
                          $PatientsTable,
                          Measurement
                        >(
                          currentTable: table,
                          referencedTable: $$PatientsTableReferences
                              ._measurementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).measurementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PatientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatientsTable,
      Patient,
      $$PatientsTableFilterComposer,
      $$PatientsTableOrderingComposer,
      $$PatientsTableAnnotationComposer,
      $$PatientsTableCreateCompanionBuilder,
      $$PatientsTableUpdateCompanionBuilder,
      (Patient, $$PatientsTableReferences),
      Patient,
      PrefetchHooks Function({bool reportsRefs, bool measurementsRefs})
    >;
typedef $$ReportsTableCreateCompanionBuilder =
    ReportsCompanion Function({
      Value<int> id,
      required int patientId,
      required DateTime examDate,
      Value<DateTime> importedAt,
      Value<String?> laboratory,
      Value<String?> reportNumber,
      required SourceKind sourceKind,
      Value<String?> sourceName,
      Value<Uint8List?> originalDocument,
      Value<String?> rawText,
      Value<String?> note,
    });
typedef $$ReportsTableUpdateCompanionBuilder =
    ReportsCompanion Function({
      Value<int> id,
      Value<int> patientId,
      Value<DateTime> examDate,
      Value<DateTime> importedAt,
      Value<String?> laboratory,
      Value<String?> reportNumber,
      Value<SourceKind> sourceKind,
      Value<String?> sourceName,
      Value<Uint8List?> originalDocument,
      Value<String?> rawText,
      Value<String?> note,
    });

final class $$ReportsTableReferences
    extends BaseReferences<_$AppDatabase, $ReportsTable, Report> {
  $$ReportsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias('reports__patient_id__patients__id');

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MeasurementsTable, List<Measurement>>
  _measurementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.measurements,
    aliasName: 'reports__id__measurements__report_id',
  );

  $$MeasurementsTableProcessedTableManager get measurementsRefs {
    final manager = $$MeasurementsTableTableManager(
      $_db,
      $_db.measurements,
    ).filter((f) => f.reportId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_measurementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReportsTableFilterComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get examDate => $composableBuilder(
    column: $table.examDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportNumber => $composableBuilder(
    column: $table.reportNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SourceKind, SourceKind, String>
  get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get originalDocument => $composableBuilder(
    column: $table.originalDocument,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> measurementsRefs(
    Expression<bool> Function($$MeasurementsTableFilterComposer f) f,
  ) {
    final $$MeasurementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurements,
      getReferencedColumn: (t) => t.reportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementsTableFilterComposer(
            $db: $db,
            $table: $db.measurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get examDate => $composableBuilder(
    column: $table.examDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportNumber => $composableBuilder(
    column: $table.reportNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get originalDocument => $composableBuilder(
    column: $table.originalDocument,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get examDate =>
      $composableBuilder(column: $table.examDate, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportNumber => $composableBuilder(
    column: $table.reportNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SourceKind, String> get sourceKind =>
      $composableBuilder(
        column: $table.sourceKind,
        builder: (column) => column,
      );

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get originalDocument => $composableBuilder(
    column: $table.originalDocument,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> measurementsRefs<T extends Object>(
    Expression<T> Function($$MeasurementsTableAnnotationComposer a) f,
  ) {
    final $$MeasurementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurements,
      getReferencedColumn: (t) => t.reportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementsTableAnnotationComposer(
            $db: $db,
            $table: $db.measurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReportsTable,
          Report,
          $$ReportsTableFilterComposer,
          $$ReportsTableOrderingComposer,
          $$ReportsTableAnnotationComposer,
          $$ReportsTableCreateCompanionBuilder,
          $$ReportsTableUpdateCompanionBuilder,
          (Report, $$ReportsTableReferences),
          Report,
          PrefetchHooks Function({bool patientId, bool measurementsRefs})
        > {
  $$ReportsTableTableManager(_$AppDatabase db, $ReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<DateTime> examDate = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<String?> laboratory = const Value.absent(),
                Value<String?> reportNumber = const Value.absent(),
                Value<SourceKind> sourceKind = const Value.absent(),
                Value<String?> sourceName = const Value.absent(),
                Value<Uint8List?> originalDocument = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => ReportsCompanion(
                id: id,
                patientId: patientId,
                examDate: examDate,
                importedAt: importedAt,
                laboratory: laboratory,
                reportNumber: reportNumber,
                sourceKind: sourceKind,
                sourceName: sourceName,
                originalDocument: originalDocument,
                rawText: rawText,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int patientId,
                required DateTime examDate,
                Value<DateTime> importedAt = const Value.absent(),
                Value<String?> laboratory = const Value.absent(),
                Value<String?> reportNumber = const Value.absent(),
                required SourceKind sourceKind,
                Value<String?> sourceName = const Value.absent(),
                Value<Uint8List?> originalDocument = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => ReportsCompanion.insert(
                id: id,
                patientId: patientId,
                examDate: examDate,
                importedAt: importedAt,
                laboratory: laboratory,
                reportNumber: reportNumber,
                sourceKind: sourceKind,
                sourceName: sourceName,
                originalDocument: originalDocument,
                rawText: rawText,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({patientId = false, measurementsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (measurementsRefs) db.measurements,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (patientId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.patientId,
                                    referencedTable: $$ReportsTableReferences
                                        ._patientIdTable(db),
                                    referencedColumn: $$ReportsTableReferences
                                        ._patientIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (measurementsRefs)
                        await $_getPrefetchedData<
                          Report,
                          $ReportsTable,
                          Measurement
                        >(
                          currentTable: table,
                          referencedTable: $$ReportsTableReferences
                              ._measurementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReportsTableReferences(
                                db,
                                table,
                                p0,
                              ).measurementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.reportId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReportsTable,
      Report,
      $$ReportsTableFilterComposer,
      $$ReportsTableOrderingComposer,
      $$ReportsTableAnnotationComposer,
      $$ReportsTableCreateCompanionBuilder,
      $$ReportsTableUpdateCompanionBuilder,
      (Report, $$ReportsTableReferences),
      Report,
      PrefetchHooks Function({bool patientId, bool measurementsRefs})
    >;
typedef $$MeasurementsTableCreateCompanionBuilder =
    MeasurementsCompanion Function({
      Value<int> id,
      required int reportId,
      required int patientId,
      required String canonicalKey,
      required String displayName,
      required String rawName,
      Value<double?> value,
      Value<String?> rawValue,
      Value<String> unit,
      Value<double?> refLow,
      Value<double?> refHigh,
      Value<StoredReferenceKind> refKind,
      Value<String?> refRaw,
      Value<String?> section,
      Value<String?> panel,
      Value<String?> note,
      Value<bool> reviewed,
    });
typedef $$MeasurementsTableUpdateCompanionBuilder =
    MeasurementsCompanion Function({
      Value<int> id,
      Value<int> reportId,
      Value<int> patientId,
      Value<String> canonicalKey,
      Value<String> displayName,
      Value<String> rawName,
      Value<double?> value,
      Value<String?> rawValue,
      Value<String> unit,
      Value<double?> refLow,
      Value<double?> refHigh,
      Value<StoredReferenceKind> refKind,
      Value<String?> refRaw,
      Value<String?> section,
      Value<String?> panel,
      Value<String?> note,
      Value<bool> reviewed,
    });

final class $$MeasurementsTableReferences
    extends BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement> {
  $$MeasurementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReportsTable _reportIdTable(_$AppDatabase db) =>
      db.reports.createAlias('measurements__report_id__reports__id');

  $$ReportsTableProcessedTableManager get reportId {
    final $_column = $_itemColumn<int>('report_id')!;

    final manager = $$ReportsTableTableManager(
      $_db,
      $_db.reports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias('measurements__patient_id__patients__id');

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalKey => $composableBuilder(
    column: $table.canonicalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawValue => $composableBuilder(
    column: $table.rawValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get refLow => $composableBuilder(
    column: $table.refLow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get refHigh => $composableBuilder(
    column: $table.refHigh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    StoredReferenceKind,
    StoredReferenceKind,
    String
  >
  get refKind => $composableBuilder(
    column: $table.refKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get refRaw => $composableBuilder(
    column: $table.refRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get panel => $composableBuilder(
    column: $table.panel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reviewed => $composableBuilder(
    column: $table.reviewed,
    builder: (column) => ColumnFilters(column),
  );

  $$ReportsTableFilterComposer get reportId {
    final $$ReportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reportId,
      referencedTable: $db.reports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportsTableFilterComposer(
            $db: $db,
            $table: $db.reports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalKey => $composableBuilder(
    column: $table.canonicalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawValue => $composableBuilder(
    column: $table.rawValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get refLow => $composableBuilder(
    column: $table.refLow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get refHigh => $composableBuilder(
    column: $table.refHigh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refKind => $composableBuilder(
    column: $table.refKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refRaw => $composableBuilder(
    column: $table.refRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get panel => $composableBuilder(
    column: $table.panel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reviewed => $composableBuilder(
    column: $table.reviewed,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReportsTableOrderingComposer get reportId {
    final $$ReportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reportId,
      referencedTable: $db.reports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportsTableOrderingComposer(
            $db: $db,
            $table: $db.reports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get canonicalKey => $composableBuilder(
    column: $table.canonicalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawName =>
      $composableBuilder(column: $table.rawName, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get rawValue =>
      $composableBuilder(column: $table.rawValue, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get refLow =>
      $composableBuilder(column: $table.refLow, builder: (column) => column);

  GeneratedColumn<double> get refHigh =>
      $composableBuilder(column: $table.refHigh, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StoredReferenceKind, String> get refKind =>
      $composableBuilder(column: $table.refKind, builder: (column) => column);

  GeneratedColumn<String> get refRaw =>
      $composableBuilder(column: $table.refRaw, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get panel =>
      $composableBuilder(column: $table.panel, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get reviewed =>
      $composableBuilder(column: $table.reviewed, builder: (column) => column);

  $$ReportsTableAnnotationComposer get reportId {
    final $$ReportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reportId,
      referencedTable: $db.reports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportsTableAnnotationComposer(
            $db: $db,
            $table: $db.reports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeasurementsTable,
          Measurement,
          $$MeasurementsTableFilterComposer,
          $$MeasurementsTableOrderingComposer,
          $$MeasurementsTableAnnotationComposer,
          $$MeasurementsTableCreateCompanionBuilder,
          $$MeasurementsTableUpdateCompanionBuilder,
          (Measurement, $$MeasurementsTableReferences),
          Measurement,
          PrefetchHooks Function({bool reportId, bool patientId})
        > {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> reportId = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<String> canonicalKey = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> rawName = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<String?> rawValue = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double?> refLow = const Value.absent(),
                Value<double?> refHigh = const Value.absent(),
                Value<StoredReferenceKind> refKind = const Value.absent(),
                Value<String?> refRaw = const Value.absent(),
                Value<String?> section = const Value.absent(),
                Value<String?> panel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> reviewed = const Value.absent(),
              }) => MeasurementsCompanion(
                id: id,
                reportId: reportId,
                patientId: patientId,
                canonicalKey: canonicalKey,
                displayName: displayName,
                rawName: rawName,
                value: value,
                rawValue: rawValue,
                unit: unit,
                refLow: refLow,
                refHigh: refHigh,
                refKind: refKind,
                refRaw: refRaw,
                section: section,
                panel: panel,
                note: note,
                reviewed: reviewed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int reportId,
                required int patientId,
                required String canonicalKey,
                required String displayName,
                required String rawName,
                Value<double?> value = const Value.absent(),
                Value<String?> rawValue = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double?> refLow = const Value.absent(),
                Value<double?> refHigh = const Value.absent(),
                Value<StoredReferenceKind> refKind = const Value.absent(),
                Value<String?> refRaw = const Value.absent(),
                Value<String?> section = const Value.absent(),
                Value<String?> panel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> reviewed = const Value.absent(),
              }) => MeasurementsCompanion.insert(
                id: id,
                reportId: reportId,
                patientId: patientId,
                canonicalKey: canonicalKey,
                displayName: displayName,
                rawName: rawName,
                value: value,
                rawValue: rawValue,
                unit: unit,
                refLow: refLow,
                refHigh: refHigh,
                refKind: refKind,
                refRaw: refRaw,
                section: section,
                panel: panel,
                note: note,
                reviewed: reviewed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MeasurementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reportId = false, patientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (reportId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.reportId,
                                referencedTable: $$MeasurementsTableReferences
                                    ._reportIdTable(db),
                                referencedColumn: $$MeasurementsTableReferences
                                    ._reportIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (patientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.patientId,
                                referencedTable: $$MeasurementsTableReferences
                                    ._patientIdTable(db),
                                referencedColumn: $$MeasurementsTableReferences
                                    ._patientIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeasurementsTable,
      Measurement,
      $$MeasurementsTableFilterComposer,
      $$MeasurementsTableOrderingComposer,
      $$MeasurementsTableAnnotationComposer,
      $$MeasurementsTableCreateCompanionBuilder,
      $$MeasurementsTableUpdateCompanionBuilder,
      (Measurement, $$MeasurementsTableReferences),
      Measurement,
      PrefetchHooks Function({bool reportId, bool patientId})
    >;
typedef $$AnalyteAliasesTableCreateCompanionBuilder =
    AnalyteAliasesCompanion Function({
      required String fromKey,
      required String toKey,
      required String fromLabel,
      required String toLabel,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AnalyteAliasesTableUpdateCompanionBuilder =
    AnalyteAliasesCompanion Function({
      Value<String> fromKey,
      Value<String> toKey,
      Value<String> fromLabel,
      Value<String> toLabel,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AnalyteAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $AnalyteAliasesTable> {
  $$AnalyteAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fromKey => $composableBuilder(
    column: $table.fromKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toKey => $composableBuilder(
    column: $table.toKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromLabel => $composableBuilder(
    column: $table.fromLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toLabel => $composableBuilder(
    column: $table.toLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnalyteAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalyteAliasesTable> {
  $$AnalyteAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fromKey => $composableBuilder(
    column: $table.fromKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toKey => $composableBuilder(
    column: $table.toKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromLabel => $composableBuilder(
    column: $table.fromLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toLabel => $composableBuilder(
    column: $table.toLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnalyteAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalyteAliasesTable> {
  $$AnalyteAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fromKey =>
      $composableBuilder(column: $table.fromKey, builder: (column) => column);

  GeneratedColumn<String> get toKey =>
      $composableBuilder(column: $table.toKey, builder: (column) => column);

  GeneratedColumn<String> get fromLabel =>
      $composableBuilder(column: $table.fromLabel, builder: (column) => column);

  GeneratedColumn<String> get toLabel =>
      $composableBuilder(column: $table.toLabel, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AnalyteAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnalyteAliasesTable,
          AnalyteAlias,
          $$AnalyteAliasesTableFilterComposer,
          $$AnalyteAliasesTableOrderingComposer,
          $$AnalyteAliasesTableAnnotationComposer,
          $$AnalyteAliasesTableCreateCompanionBuilder,
          $$AnalyteAliasesTableUpdateCompanionBuilder,
          (
            AnalyteAlias,
            BaseReferences<_$AppDatabase, $AnalyteAliasesTable, AnalyteAlias>,
          ),
          AnalyteAlias,
          PrefetchHooks Function()
        > {
  $$AnalyteAliasesTableTableManager(
    _$AppDatabase db,
    $AnalyteAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalyteAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalyteAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalyteAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fromKey = const Value.absent(),
                Value<String> toKey = const Value.absent(),
                Value<String> fromLabel = const Value.absent(),
                Value<String> toLabel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalyteAliasesCompanion(
                fromKey: fromKey,
                toKey: toKey,
                fromLabel: fromLabel,
                toLabel: toLabel,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fromKey,
                required String toKey,
                required String fromLabel,
                required String toLabel,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalyteAliasesCompanion.insert(
                fromKey: fromKey,
                toKey: toKey,
                fromLabel: fromLabel,
                toLabel: toLabel,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnalyteAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnalyteAliasesTable,
      AnalyteAlias,
      $$AnalyteAliasesTableFilterComposer,
      $$AnalyteAliasesTableOrderingComposer,
      $$AnalyteAliasesTableAnnotationComposer,
      $$AnalyteAliasesTableCreateCompanionBuilder,
      $$AnalyteAliasesTableUpdateCompanionBuilder,
      (
        AnalyteAlias,
        BaseReferences<_$AppDatabase, $AnalyteAliasesTable, AnalyteAlias>,
      ),
      AnalyteAlias,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db, _db.patients);
  $$ReportsTableTableManager get reports =>
      $$ReportsTableTableManager(_db, _db.reports);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$AnalyteAliasesTableTableManager get analyteAliases =>
      $$AnalyteAliasesTableTableManager(_db, _db.analyteAliases);
}
