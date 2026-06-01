// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CollectionItemsTable extends CollectionItems
    with TableInfo<$CollectionItemsTable, CollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discogsReleaseIdMeta = const VerificationMeta(
    'discogsReleaseId',
  );
  @override
  late final GeneratedColumn<int> discogsReleaseId = GeneratedColumn<int>(
    'discogs_release_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catnoMeta = const VerificationMeta('catno');
  @override
  late final GeneratedColumn<String> catno = GeneratedColumn<String>(
    'catno',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecordCondition, String>
  mediaCondition =
      GeneratedColumn<String>(
        'media_condition',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecordCondition>(
        $CollectionItemsTable.$convertermediaCondition,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RecordCondition, String>
  sleeveCondition =
      GeneratedColumn<String>(
        'sleeve_condition',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecordCondition>(
        $CollectionItemsTable.$convertersleeveCondition,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($CollectionItemsTable.$convertertags);
  static const VerificationMeta _storageLocationMeta = const VerificationMeta(
    'storageLocation',
  );
  @override
  late final GeneratedColumn<String> storageLocation = GeneratedColumn<String>(
    'storage_location',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    discogsReleaseId,
    artist,
    title,
    label,
    catno,
    format,
    country,
    year,
    coverUrl,
    mediaCondition,
    sleeveCondition,
    notes,
    tags,
    storageLocation,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('discogs_release_id')) {
      context.handle(
        _discogsReleaseIdMeta,
        discogsReleaseId.isAcceptableOrUnknown(
          data['discogs_release_id']!,
          _discogsReleaseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discogsReleaseIdMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('catno')) {
      context.handle(
        _catnoMeta,
        catno.isAcceptableOrUnknown(data['catno']!, _catnoMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('storage_location')) {
      context.handle(
        _storageLocationMeta,
        storageLocation.isAcceptableOrUnknown(
          data['storage_location']!,
          _storageLocationMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      discogsReleaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discogs_release_id'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      catno: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catno'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      mediaCondition: $CollectionItemsTable.$convertermediaCondition.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_condition'],
        )!,
      ),
      sleeveCondition: $CollectionItemsTable.$convertersleeveCondition.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sleeve_condition'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      tags: $CollectionItemsTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      storageLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_location'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CollectionItemsTable createAlias(String alias) {
    return $CollectionItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<RecordCondition, String> $convertermediaCondition =
      const RecordConditionConverter();
  static TypeConverter<RecordCondition, String> $convertersleeveCondition =
      const RecordConditionConverter();
  static TypeConverter<List<String>, String> $convertertags =
      const StringListConverter();
}

class CollectionRow extends DataClass implements Insertable<CollectionRow> {
  final String id;
  final int discogsReleaseId;
  final String artist;
  final String title;
  final String? label;
  final String? catno;
  final String? format;
  final String? country;
  final int? year;
  final String? coverUrl;
  final RecordCondition mediaCondition;
  final RecordCondition sleeveCondition;
  final String? notes;
  final List<String> tags;
  final String? storageLocation;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CollectionRow({
    required this.id,
    required this.discogsReleaseId,
    required this.artist,
    required this.title,
    this.label,
    this.catno,
    this.format,
    this.country,
    this.year,
    this.coverUrl,
    required this.mediaCondition,
    required this.sleeveCondition,
    this.notes,
    required this.tags,
    this.storageLocation,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['discogs_release_id'] = Variable<int>(discogsReleaseId);
    map['artist'] = Variable<String>(artist);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || catno != null) {
      map['catno'] = Variable<String>(catno);
    }
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    {
      map['media_condition'] = Variable<String>(
        $CollectionItemsTable.$convertermediaCondition.toSql(mediaCondition),
      );
    }
    {
      map['sleeve_condition'] = Variable<String>(
        $CollectionItemsTable.$convertersleeveCondition.toSql(sleeveCondition),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['tags'] = Variable<String>(
        $CollectionItemsTable.$convertertags.toSql(tags),
      );
    }
    if (!nullToAbsent || storageLocation != null) {
      map['storage_location'] = Variable<String>(storageLocation);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CollectionItemsCompanion toCompanion(bool nullToAbsent) {
    return CollectionItemsCompanion(
      id: Value(id),
      discogsReleaseId: Value(discogsReleaseId),
      artist: Value(artist),
      title: Value(title),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      catno: catno == null && nullToAbsent
          ? const Value.absent()
          : Value(catno),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      mediaCondition: Value(mediaCondition),
      sleeveCondition: Value(sleeveCondition),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      tags: Value(tags),
      storageLocation: storageLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(storageLocation),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CollectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionRow(
      id: serializer.fromJson<String>(json['id']),
      discogsReleaseId: serializer.fromJson<int>(json['discogsReleaseId']),
      artist: serializer.fromJson<String>(json['artist']),
      title: serializer.fromJson<String>(json['title']),
      label: serializer.fromJson<String?>(json['label']),
      catno: serializer.fromJson<String?>(json['catno']),
      format: serializer.fromJson<String?>(json['format']),
      country: serializer.fromJson<String?>(json['country']),
      year: serializer.fromJson<int?>(json['year']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      mediaCondition: serializer.fromJson<RecordCondition>(
        json['mediaCondition'],
      ),
      sleeveCondition: serializer.fromJson<RecordCondition>(
        json['sleeveCondition'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      storageLocation: serializer.fromJson<String?>(json['storageLocation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'discogsReleaseId': serializer.toJson<int>(discogsReleaseId),
      'artist': serializer.toJson<String>(artist),
      'title': serializer.toJson<String>(title),
      'label': serializer.toJson<String?>(label),
      'catno': serializer.toJson<String?>(catno),
      'format': serializer.toJson<String?>(format),
      'country': serializer.toJson<String?>(country),
      'year': serializer.toJson<int?>(year),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'mediaCondition': serializer.toJson<RecordCondition>(mediaCondition),
      'sleeveCondition': serializer.toJson<RecordCondition>(sleeveCondition),
      'notes': serializer.toJson<String?>(notes),
      'tags': serializer.toJson<List<String>>(tags),
      'storageLocation': serializer.toJson<String?>(storageLocation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CollectionRow copyWith({
    String? id,
    int? discogsReleaseId,
    String? artist,
    String? title,
    Value<String?> label = const Value.absent(),
    Value<String?> catno = const Value.absent(),
    Value<String?> format = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    RecordCondition? mediaCondition,
    RecordCondition? sleeveCondition,
    Value<String?> notes = const Value.absent(),
    List<String>? tags,
    Value<String?> storageLocation = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CollectionRow(
    id: id ?? this.id,
    discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
    artist: artist ?? this.artist,
    title: title ?? this.title,
    label: label.present ? label.value : this.label,
    catno: catno.present ? catno.value : this.catno,
    format: format.present ? format.value : this.format,
    country: country.present ? country.value : this.country,
    year: year.present ? year.value : this.year,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    mediaCondition: mediaCondition ?? this.mediaCondition,
    sleeveCondition: sleeveCondition ?? this.sleeveCondition,
    notes: notes.present ? notes.value : this.notes,
    tags: tags ?? this.tags,
    storageLocation: storageLocation.present
        ? storageLocation.value
        : this.storageLocation,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CollectionRow copyWithCompanion(CollectionItemsCompanion data) {
    return CollectionRow(
      id: data.id.present ? data.id.value : this.id,
      discogsReleaseId: data.discogsReleaseId.present
          ? data.discogsReleaseId.value
          : this.discogsReleaseId,
      artist: data.artist.present ? data.artist.value : this.artist,
      title: data.title.present ? data.title.value : this.title,
      label: data.label.present ? data.label.value : this.label,
      catno: data.catno.present ? data.catno.value : this.catno,
      format: data.format.present ? data.format.value : this.format,
      country: data.country.present ? data.country.value : this.country,
      year: data.year.present ? data.year.value : this.year,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      mediaCondition: data.mediaCondition.present
          ? data.mediaCondition.value
          : this.mediaCondition,
      sleeveCondition: data.sleeveCondition.present
          ? data.sleeveCondition.value
          : this.sleeveCondition,
      notes: data.notes.present ? data.notes.value : this.notes,
      tags: data.tags.present ? data.tags.value : this.tags,
      storageLocation: data.storageLocation.present
          ? data.storageLocation.value
          : this.storageLocation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionRow(')
          ..write('id: $id, ')
          ..write('discogsReleaseId: $discogsReleaseId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('label: $label, ')
          ..write('catno: $catno, ')
          ..write('format: $format, ')
          ..write('country: $country, ')
          ..write('year: $year, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('mediaCondition: $mediaCondition, ')
          ..write('sleeveCondition: $sleeveCondition, ')
          ..write('notes: $notes, ')
          ..write('tags: $tags, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    discogsReleaseId,
    artist,
    title,
    label,
    catno,
    format,
    country,
    year,
    coverUrl,
    mediaCondition,
    sleeveCondition,
    notes,
    tags,
    storageLocation,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionRow &&
          other.id == this.id &&
          other.discogsReleaseId == this.discogsReleaseId &&
          other.artist == this.artist &&
          other.title == this.title &&
          other.label == this.label &&
          other.catno == this.catno &&
          other.format == this.format &&
          other.country == this.country &&
          other.year == this.year &&
          other.coverUrl == this.coverUrl &&
          other.mediaCondition == this.mediaCondition &&
          other.sleeveCondition == this.sleeveCondition &&
          other.notes == this.notes &&
          other.tags == this.tags &&
          other.storageLocation == this.storageLocation &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CollectionItemsCompanion extends UpdateCompanion<CollectionRow> {
  final Value<String> id;
  final Value<int> discogsReleaseId;
  final Value<String> artist;
  final Value<String> title;
  final Value<String?> label;
  final Value<String?> catno;
  final Value<String?> format;
  final Value<String?> country;
  final Value<int?> year;
  final Value<String?> coverUrl;
  final Value<RecordCondition> mediaCondition;
  final Value<RecordCondition> sleeveCondition;
  final Value<String?> notes;
  final Value<List<String>> tags;
  final Value<String?> storageLocation;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CollectionItemsCompanion({
    this.id = const Value.absent(),
    this.discogsReleaseId = const Value.absent(),
    this.artist = const Value.absent(),
    this.title = const Value.absent(),
    this.label = const Value.absent(),
    this.catno = const Value.absent(),
    this.format = const Value.absent(),
    this.country = const Value.absent(),
    this.year = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.mediaCondition = const Value.absent(),
    this.sleeveCondition = const Value.absent(),
    this.notes = const Value.absent(),
    this.tags = const Value.absent(),
    this.storageLocation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionItemsCompanion.insert({
    required String id,
    required int discogsReleaseId,
    required String artist,
    required String title,
    this.label = const Value.absent(),
    this.catno = const Value.absent(),
    this.format = const Value.absent(),
    this.country = const Value.absent(),
    this.year = const Value.absent(),
    this.coverUrl = const Value.absent(),
    required RecordCondition mediaCondition,
    required RecordCondition sleeveCondition,
    this.notes = const Value.absent(),
    required List<String> tags,
    this.storageLocation = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       discogsReleaseId = Value(discogsReleaseId),
       artist = Value(artist),
       title = Value(title),
       mediaCondition = Value(mediaCondition),
       sleeveCondition = Value(sleeveCondition),
       tags = Value(tags),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CollectionRow> custom({
    Expression<String>? id,
    Expression<int>? discogsReleaseId,
    Expression<String>? artist,
    Expression<String>? title,
    Expression<String>? label,
    Expression<String>? catno,
    Expression<String>? format,
    Expression<String>? country,
    Expression<int>? year,
    Expression<String>? coverUrl,
    Expression<String>? mediaCondition,
    Expression<String>? sleeveCondition,
    Expression<String>? notes,
    Expression<String>? tags,
    Expression<String>? storageLocation,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (discogsReleaseId != null) 'discogs_release_id': discogsReleaseId,
      if (artist != null) 'artist': artist,
      if (title != null) 'title': title,
      if (label != null) 'label': label,
      if (catno != null) 'catno': catno,
      if (format != null) 'format': format,
      if (country != null) 'country': country,
      if (year != null) 'year': year,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (mediaCondition != null) 'media_condition': mediaCondition,
      if (sleeveCondition != null) 'sleeve_condition': sleeveCondition,
      if (notes != null) 'notes': notes,
      if (tags != null) 'tags': tags,
      if (storageLocation != null) 'storage_location': storageLocation,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? discogsReleaseId,
    Value<String>? artist,
    Value<String>? title,
    Value<String?>? label,
    Value<String?>? catno,
    Value<String?>? format,
    Value<String?>? country,
    Value<int?>? year,
    Value<String?>? coverUrl,
    Value<RecordCondition>? mediaCondition,
    Value<RecordCondition>? sleeveCondition,
    Value<String?>? notes,
    Value<List<String>>? tags,
    Value<String?>? storageLocation,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CollectionItemsCompanion(
      id: id ?? this.id,
      discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      label: label ?? this.label,
      catno: catno ?? this.catno,
      format: format ?? this.format,
      country: country ?? this.country,
      year: year ?? this.year,
      coverUrl: coverUrl ?? this.coverUrl,
      mediaCondition: mediaCondition ?? this.mediaCondition,
      sleeveCondition: sleeveCondition ?? this.sleeveCondition,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      storageLocation: storageLocation ?? this.storageLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (discogsReleaseId.present) {
      map['discogs_release_id'] = Variable<int>(discogsReleaseId.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (catno.present) {
      map['catno'] = Variable<String>(catno.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (mediaCondition.present) {
      map['media_condition'] = Variable<String>(
        $CollectionItemsTable.$convertermediaCondition.toSql(
          mediaCondition.value,
        ),
      );
    }
    if (sleeveCondition.present) {
      map['sleeve_condition'] = Variable<String>(
        $CollectionItemsTable.$convertersleeveCondition.toSql(
          sleeveCondition.value,
        ),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $CollectionItemsTable.$convertertags.toSql(tags.value),
      );
    }
    if (storageLocation.present) {
      map['storage_location'] = Variable<String>(storageLocation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemsCompanion(')
          ..write('id: $id, ')
          ..write('discogsReleaseId: $discogsReleaseId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('label: $label, ')
          ..write('catno: $catno, ')
          ..write('format: $format, ')
          ..write('country: $country, ')
          ..write('year: $year, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('mediaCondition: $mediaCondition, ')
          ..write('sleeveCondition: $sleeveCondition, ')
          ..write('notes: $notes, ')
          ..write('tags: $tags, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WishlistItemsTable extends WishlistItems
    with TableInfo<$WishlistItemsTable, WishlistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WishlistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discogsReleaseIdMeta = const VerificationMeta(
    'discogsReleaseId',
  );
  @override
  late final GeneratedColumn<int> discogsReleaseId = GeneratedColumn<int>(
    'discogs_release_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catnoMeta = const VerificationMeta('catno');
  @override
  late final GeneratedColumn<String> catno = GeneratedColumn<String>(
    'catno',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetPriceMeta = const VerificationMeta(
    'targetPrice',
  );
  @override
  late final GeneratedColumn<double> targetPrice = GeneratedColumn<double>(
    'target_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WishlistPriority, String>
  priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<WishlistPriority>($WishlistItemsTable.$converterpriority);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    discogsReleaseId,
    artist,
    title,
    label,
    catno,
    format,
    country,
    year,
    coverUrl,
    targetPrice,
    priority,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wishlist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WishlistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('discogs_release_id')) {
      context.handle(
        _discogsReleaseIdMeta,
        discogsReleaseId.isAcceptableOrUnknown(
          data['discogs_release_id']!,
          _discogsReleaseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discogsReleaseIdMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('catno')) {
      context.handle(
        _catnoMeta,
        catno.isAcceptableOrUnknown(data['catno']!, _catnoMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('target_price')) {
      context.handle(
        _targetPriceMeta,
        targetPrice.isAcceptableOrUnknown(
          data['target_price']!,
          _targetPriceMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WishlistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WishlistRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      discogsReleaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discogs_release_id'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      catno: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catno'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      targetPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_price'],
      ),
      priority: $WishlistItemsTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WishlistItemsTable createAlias(String alias) {
    return $WishlistItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<WishlistPriority, String> $converterpriority =
      const WishlistPriorityConverter();
}

class WishlistRow extends DataClass implements Insertable<WishlistRow> {
  final String id;
  final int discogsReleaseId;
  final String artist;
  final String title;
  final String? label;
  final String? catno;
  final String? format;
  final String? country;
  final int? year;
  final String? coverUrl;
  final double? targetPrice;
  final WishlistPriority priority;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WishlistRow({
    required this.id,
    required this.discogsReleaseId,
    required this.artist,
    required this.title,
    this.label,
    this.catno,
    this.format,
    this.country,
    this.year,
    this.coverUrl,
    this.targetPrice,
    required this.priority,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['discogs_release_id'] = Variable<int>(discogsReleaseId);
    map['artist'] = Variable<String>(artist);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || catno != null) {
      map['catno'] = Variable<String>(catno);
    }
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || targetPrice != null) {
      map['target_price'] = Variable<double>(targetPrice);
    }
    {
      map['priority'] = Variable<String>(
        $WishlistItemsTable.$converterpriority.toSql(priority),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WishlistItemsCompanion toCompanion(bool nullToAbsent) {
    return WishlistItemsCompanion(
      id: Value(id),
      discogsReleaseId: Value(discogsReleaseId),
      artist: Value(artist),
      title: Value(title),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      catno: catno == null && nullToAbsent
          ? const Value.absent()
          : Value(catno),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      targetPrice: targetPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPrice),
      priority: Value(priority),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WishlistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WishlistRow(
      id: serializer.fromJson<String>(json['id']),
      discogsReleaseId: serializer.fromJson<int>(json['discogsReleaseId']),
      artist: serializer.fromJson<String>(json['artist']),
      title: serializer.fromJson<String>(json['title']),
      label: serializer.fromJson<String?>(json['label']),
      catno: serializer.fromJson<String?>(json['catno']),
      format: serializer.fromJson<String?>(json['format']),
      country: serializer.fromJson<String?>(json['country']),
      year: serializer.fromJson<int?>(json['year']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      targetPrice: serializer.fromJson<double?>(json['targetPrice']),
      priority: serializer.fromJson<WishlistPriority>(json['priority']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'discogsReleaseId': serializer.toJson<int>(discogsReleaseId),
      'artist': serializer.toJson<String>(artist),
      'title': serializer.toJson<String>(title),
      'label': serializer.toJson<String?>(label),
      'catno': serializer.toJson<String?>(catno),
      'format': serializer.toJson<String?>(format),
      'country': serializer.toJson<String?>(country),
      'year': serializer.toJson<int?>(year),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'targetPrice': serializer.toJson<double?>(targetPrice),
      'priority': serializer.toJson<WishlistPriority>(priority),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WishlistRow copyWith({
    String? id,
    int? discogsReleaseId,
    String? artist,
    String? title,
    Value<String?> label = const Value.absent(),
    Value<String?> catno = const Value.absent(),
    Value<String?> format = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<double?> targetPrice = const Value.absent(),
    WishlistPriority? priority,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WishlistRow(
    id: id ?? this.id,
    discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
    artist: artist ?? this.artist,
    title: title ?? this.title,
    label: label.present ? label.value : this.label,
    catno: catno.present ? catno.value : this.catno,
    format: format.present ? format.value : this.format,
    country: country.present ? country.value : this.country,
    year: year.present ? year.value : this.year,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    targetPrice: targetPrice.present ? targetPrice.value : this.targetPrice,
    priority: priority ?? this.priority,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WishlistRow copyWithCompanion(WishlistItemsCompanion data) {
    return WishlistRow(
      id: data.id.present ? data.id.value : this.id,
      discogsReleaseId: data.discogsReleaseId.present
          ? data.discogsReleaseId.value
          : this.discogsReleaseId,
      artist: data.artist.present ? data.artist.value : this.artist,
      title: data.title.present ? data.title.value : this.title,
      label: data.label.present ? data.label.value : this.label,
      catno: data.catno.present ? data.catno.value : this.catno,
      format: data.format.present ? data.format.value : this.format,
      country: data.country.present ? data.country.value : this.country,
      year: data.year.present ? data.year.value : this.year,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      targetPrice: data.targetPrice.present
          ? data.targetPrice.value
          : this.targetPrice,
      priority: data.priority.present ? data.priority.value : this.priority,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WishlistRow(')
          ..write('id: $id, ')
          ..write('discogsReleaseId: $discogsReleaseId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('label: $label, ')
          ..write('catno: $catno, ')
          ..write('format: $format, ')
          ..write('country: $country, ')
          ..write('year: $year, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('targetPrice: $targetPrice, ')
          ..write('priority: $priority, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    discogsReleaseId,
    artist,
    title,
    label,
    catno,
    format,
    country,
    year,
    coverUrl,
    targetPrice,
    priority,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WishlistRow &&
          other.id == this.id &&
          other.discogsReleaseId == this.discogsReleaseId &&
          other.artist == this.artist &&
          other.title == this.title &&
          other.label == this.label &&
          other.catno == this.catno &&
          other.format == this.format &&
          other.country == this.country &&
          other.year == this.year &&
          other.coverUrl == this.coverUrl &&
          other.targetPrice == this.targetPrice &&
          other.priority == this.priority &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WishlistItemsCompanion extends UpdateCompanion<WishlistRow> {
  final Value<String> id;
  final Value<int> discogsReleaseId;
  final Value<String> artist;
  final Value<String> title;
  final Value<String?> label;
  final Value<String?> catno;
  final Value<String?> format;
  final Value<String?> country;
  final Value<int?> year;
  final Value<String?> coverUrl;
  final Value<double?> targetPrice;
  final Value<WishlistPriority> priority;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WishlistItemsCompanion({
    this.id = const Value.absent(),
    this.discogsReleaseId = const Value.absent(),
    this.artist = const Value.absent(),
    this.title = const Value.absent(),
    this.label = const Value.absent(),
    this.catno = const Value.absent(),
    this.format = const Value.absent(),
    this.country = const Value.absent(),
    this.year = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.targetPrice = const Value.absent(),
    this.priority = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WishlistItemsCompanion.insert({
    required String id,
    required int discogsReleaseId,
    required String artist,
    required String title,
    this.label = const Value.absent(),
    this.catno = const Value.absent(),
    this.format = const Value.absent(),
    this.country = const Value.absent(),
    this.year = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.targetPrice = const Value.absent(),
    required WishlistPriority priority,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       discogsReleaseId = Value(discogsReleaseId),
       artist = Value(artist),
       title = Value(title),
       priority = Value(priority),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WishlistRow> custom({
    Expression<String>? id,
    Expression<int>? discogsReleaseId,
    Expression<String>? artist,
    Expression<String>? title,
    Expression<String>? label,
    Expression<String>? catno,
    Expression<String>? format,
    Expression<String>? country,
    Expression<int>? year,
    Expression<String>? coverUrl,
    Expression<double>? targetPrice,
    Expression<String>? priority,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (discogsReleaseId != null) 'discogs_release_id': discogsReleaseId,
      if (artist != null) 'artist': artist,
      if (title != null) 'title': title,
      if (label != null) 'label': label,
      if (catno != null) 'catno': catno,
      if (format != null) 'format': format,
      if (country != null) 'country': country,
      if (year != null) 'year': year,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (targetPrice != null) 'target_price': targetPrice,
      if (priority != null) 'priority': priority,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WishlistItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? discogsReleaseId,
    Value<String>? artist,
    Value<String>? title,
    Value<String?>? label,
    Value<String?>? catno,
    Value<String?>? format,
    Value<String?>? country,
    Value<int?>? year,
    Value<String?>? coverUrl,
    Value<double?>? targetPrice,
    Value<WishlistPriority>? priority,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WishlistItemsCompanion(
      id: id ?? this.id,
      discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      label: label ?? this.label,
      catno: catno ?? this.catno,
      format: format ?? this.format,
      country: country ?? this.country,
      year: year ?? this.year,
      coverUrl: coverUrl ?? this.coverUrl,
      targetPrice: targetPrice ?? this.targetPrice,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (discogsReleaseId.present) {
      map['discogs_release_id'] = Variable<int>(discogsReleaseId.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (catno.present) {
      map['catno'] = Variable<String>(catno.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (targetPrice.present) {
      map['target_price'] = Variable<double>(targetPrice.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $WishlistItemsTable.$converterpriority.toSql(priority.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WishlistItemsCompanion(')
          ..write('id: $id, ')
          ..write('discogsReleaseId: $discogsReleaseId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('label: $label, ')
          ..write('catno: $catno, ')
          ..write('format: $format, ')
          ..write('country: $country, ')
          ..write('year: $year, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('targetPrice: $targetPrice, ')
          ..write('priority: $priority, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CollectionItemsTable collectionItems = $CollectionItemsTable(
    this,
  );
  late final $WishlistItemsTable wishlistItems = $WishlistItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    collectionItems,
    wishlistItems,
  ];
}

typedef $$CollectionItemsTableCreateCompanionBuilder =
    CollectionItemsCompanion Function({
      required String id,
      required int discogsReleaseId,
      required String artist,
      required String title,
      Value<String?> label,
      Value<String?> catno,
      Value<String?> format,
      Value<String?> country,
      Value<int?> year,
      Value<String?> coverUrl,
      required RecordCondition mediaCondition,
      required RecordCondition sleeveCondition,
      Value<String?> notes,
      required List<String> tags,
      Value<String?> storageLocation,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CollectionItemsTableUpdateCompanionBuilder =
    CollectionItemsCompanion Function({
      Value<String> id,
      Value<int> discogsReleaseId,
      Value<String> artist,
      Value<String> title,
      Value<String?> label,
      Value<String?> catno,
      Value<String?> format,
      Value<String?> country,
      Value<int?> year,
      Value<String?> coverUrl,
      Value<RecordCondition> mediaCondition,
      Value<RecordCondition> sleeveCondition,
      Value<String?> notes,
      Value<List<String>> tags,
      Value<String?> storageLocation,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CollectionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discogsReleaseId => $composableBuilder(
    column: $table.discogsReleaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catno => $composableBuilder(
    column: $table.catno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecordCondition, RecordCondition, String>
  get mediaCondition => $composableBuilder(
    column: $table.mediaCondition,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<RecordCondition, RecordCondition, String>
  get sleeveCondition => $composableBuilder(
    column: $table.sleeveCondition,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discogsReleaseId => $composableBuilder(
    column: $table.discogsReleaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catno => $composableBuilder(
    column: $table.catno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaCondition => $composableBuilder(
    column: $table.mediaCondition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sleeveCondition => $composableBuilder(
    column: $table.sleeveCondition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get discogsReleaseId => $composableBuilder(
    column: $table.discogsReleaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get catno =>
      $composableBuilder(column: $table.catno, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecordCondition, String>
  get mediaCondition => $composableBuilder(
    column: $table.mediaCondition,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecordCondition, String>
  get sleeveCondition => $composableBuilder(
    column: $table.sleeveCondition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CollectionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionItemsTable,
          CollectionRow,
          $$CollectionItemsTableFilterComposer,
          $$CollectionItemsTableOrderingComposer,
          $$CollectionItemsTableAnnotationComposer,
          $$CollectionItemsTableCreateCompanionBuilder,
          $$CollectionItemsTableUpdateCompanionBuilder,
          (
            CollectionRow,
            BaseReferences<_$AppDatabase, $CollectionItemsTable, CollectionRow>,
          ),
          CollectionRow,
          PrefetchHooks Function()
        > {
  $$CollectionItemsTableTableManager(
    _$AppDatabase db,
    $CollectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> discogsReleaseId = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> catno = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<RecordCondition> mediaCondition = const Value.absent(),
                Value<RecordCondition> sleeveCondition = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<String?> storageLocation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion(
                id: id,
                discogsReleaseId: discogsReleaseId,
                artist: artist,
                title: title,
                label: label,
                catno: catno,
                format: format,
                country: country,
                year: year,
                coverUrl: coverUrl,
                mediaCondition: mediaCondition,
                sleeveCondition: sleeveCondition,
                notes: notes,
                tags: tags,
                storageLocation: storageLocation,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int discogsReleaseId,
                required String artist,
                required String title,
                Value<String?> label = const Value.absent(),
                Value<String?> catno = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                required RecordCondition mediaCondition,
                required RecordCondition sleeveCondition,
                Value<String?> notes = const Value.absent(),
                required List<String> tags,
                Value<String?> storageLocation = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion.insert(
                id: id,
                discogsReleaseId: discogsReleaseId,
                artist: artist,
                title: title,
                label: label,
                catno: catno,
                format: format,
                country: country,
                year: year,
                coverUrl: coverUrl,
                mediaCondition: mediaCondition,
                sleeveCondition: sleeveCondition,
                notes: notes,
                tags: tags,
                storageLocation: storageLocation,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionItemsTable,
      CollectionRow,
      $$CollectionItemsTableFilterComposer,
      $$CollectionItemsTableOrderingComposer,
      $$CollectionItemsTableAnnotationComposer,
      $$CollectionItemsTableCreateCompanionBuilder,
      $$CollectionItemsTableUpdateCompanionBuilder,
      (
        CollectionRow,
        BaseReferences<_$AppDatabase, $CollectionItemsTable, CollectionRow>,
      ),
      CollectionRow,
      PrefetchHooks Function()
    >;
typedef $$WishlistItemsTableCreateCompanionBuilder =
    WishlistItemsCompanion Function({
      required String id,
      required int discogsReleaseId,
      required String artist,
      required String title,
      Value<String?> label,
      Value<String?> catno,
      Value<String?> format,
      Value<String?> country,
      Value<int?> year,
      Value<String?> coverUrl,
      Value<double?> targetPrice,
      required WishlistPriority priority,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WishlistItemsTableUpdateCompanionBuilder =
    WishlistItemsCompanion Function({
      Value<String> id,
      Value<int> discogsReleaseId,
      Value<String> artist,
      Value<String> title,
      Value<String?> label,
      Value<String?> catno,
      Value<String?> format,
      Value<String?> country,
      Value<int?> year,
      Value<String?> coverUrl,
      Value<double?> targetPrice,
      Value<WishlistPriority> priority,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WishlistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $WishlistItemsTable> {
  $$WishlistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discogsReleaseId => $composableBuilder(
    column: $table.discogsReleaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catno => $composableBuilder(
    column: $table.catno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WishlistPriority, WishlistPriority, String>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WishlistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $WishlistItemsTable> {
  $$WishlistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discogsReleaseId => $composableBuilder(
    column: $table.discogsReleaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catno => $composableBuilder(
    column: $table.catno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WishlistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WishlistItemsTable> {
  $$WishlistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get discogsReleaseId => $composableBuilder(
    column: $table.discogsReleaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get catno =>
      $composableBuilder(column: $table.catno, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WishlistPriority, String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WishlistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WishlistItemsTable,
          WishlistRow,
          $$WishlistItemsTableFilterComposer,
          $$WishlistItemsTableOrderingComposer,
          $$WishlistItemsTableAnnotationComposer,
          $$WishlistItemsTableCreateCompanionBuilder,
          $$WishlistItemsTableUpdateCompanionBuilder,
          (
            WishlistRow,
            BaseReferences<_$AppDatabase, $WishlistItemsTable, WishlistRow>,
          ),
          WishlistRow,
          PrefetchHooks Function()
        > {
  $$WishlistItemsTableTableManager(_$AppDatabase db, $WishlistItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WishlistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WishlistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WishlistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> discogsReleaseId = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> catno = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<double?> targetPrice = const Value.absent(),
                Value<WishlistPriority> priority = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WishlistItemsCompanion(
                id: id,
                discogsReleaseId: discogsReleaseId,
                artist: artist,
                title: title,
                label: label,
                catno: catno,
                format: format,
                country: country,
                year: year,
                coverUrl: coverUrl,
                targetPrice: targetPrice,
                priority: priority,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int discogsReleaseId,
                required String artist,
                required String title,
                Value<String?> label = const Value.absent(),
                Value<String?> catno = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<double?> targetPrice = const Value.absent(),
                required WishlistPriority priority,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WishlistItemsCompanion.insert(
                id: id,
                discogsReleaseId: discogsReleaseId,
                artist: artist,
                title: title,
                label: label,
                catno: catno,
                format: format,
                country: country,
                year: year,
                coverUrl: coverUrl,
                targetPrice: targetPrice,
                priority: priority,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WishlistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WishlistItemsTable,
      WishlistRow,
      $$WishlistItemsTableFilterComposer,
      $$WishlistItemsTableOrderingComposer,
      $$WishlistItemsTableAnnotationComposer,
      $$WishlistItemsTableCreateCompanionBuilder,
      $$WishlistItemsTableUpdateCompanionBuilder,
      (
        WishlistRow,
        BaseReferences<_$AppDatabase, $WishlistItemsTable, WishlistRow>,
      ),
      WishlistRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CollectionItemsTableTableManager get collectionItems =>
      $$CollectionItemsTableTableManager(_db, _db.collectionItems);
  $$WishlistItemsTableTableManager get wishlistItems =>
      $$WishlistItemsTableTableManager(_db, _db.wishlistItems);
}
