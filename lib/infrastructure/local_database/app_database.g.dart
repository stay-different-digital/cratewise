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
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus?, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SyncStatus?>($CollectionItemsTable.$convertersyncStatusn);
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
    syncStatus,
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
      syncStatus: $CollectionItemsTable.$convertersyncStatusn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        ),
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
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
  static TypeConverter<SyncStatus?, String?> $convertersyncStatusn =
      NullAwareTypeConverter.wrap($convertersyncStatus);
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
  final SyncStatus? syncStatus;
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
    this.syncStatus,
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
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(
        $CollectionItemsTable.$convertersyncStatusn.toSql(syncStatus),
      );
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
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
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
      syncStatus: serializer.fromJson<SyncStatus?>(json['syncStatus']),
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
      'syncStatus': serializer.toJson<SyncStatus?>(syncStatus),
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
    Value<SyncStatus?> syncStatus = const Value.absent(),
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
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
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
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
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
          ..write('syncStatus: $syncStatus, ')
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
    syncStatus,
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
          other.syncStatus == this.syncStatus &&
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
  final Value<SyncStatus?> syncStatus;
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
    this.syncStatus = const Value.absent(),
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
    this.syncStatus = const Value.absent(),
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
    Expression<String>? syncStatus,
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
      if (syncStatus != null) 'sync_status': syncStatus,
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
    Value<SyncStatus?>? syncStatus,
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
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $CollectionItemsTable.$convertersyncStatusn.toSql(syncStatus.value),
      );
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
          ..write('syncStatus: $syncStatus, ')
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
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus?, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SyncStatus?>($WishlistItemsTable.$convertersyncStatusn);
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
    syncStatus,
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
      syncStatus: $WishlistItemsTable.$convertersyncStatusn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        ),
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
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
  static TypeConverter<SyncStatus?, String?> $convertersyncStatusn =
      NullAwareTypeConverter.wrap($convertersyncStatus);
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
  final SyncStatus? syncStatus;
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
    this.syncStatus,
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
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(
        $WishlistItemsTable.$convertersyncStatusn.toSql(syncStatus),
      );
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
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
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
      syncStatus: serializer.fromJson<SyncStatus?>(json['syncStatus']),
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
      'syncStatus': serializer.toJson<SyncStatus?>(syncStatus),
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
    Value<SyncStatus?> syncStatus = const Value.absent(),
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
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
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
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
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
          ..write('syncStatus: $syncStatus, ')
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
    syncStatus,
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
          other.syncStatus == this.syncStatus &&
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
  final Value<SyncStatus?> syncStatus;
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
    this.syncStatus = const Value.absent(),
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
    this.syncStatus = const Value.absent(),
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
    Expression<String>? syncStatus,
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
      if (syncStatus != null) 'sync_status': syncStatus,
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
    Value<SyncStatus?>? syncStatus,
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
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $WishlistItemsTable.$convertersyncStatusn.toSql(syncStatus.value),
      );
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
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedReleasesTable extends CachedReleases
    with TableInfo<$CachedReleasesTable, CachedReleaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedReleasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _discogsReleaseIdMeta = const VerificationMeta(
    'discogsReleaseId',
  );
  @override
  late final GeneratedColumn<int> discogsReleaseId = GeneratedColumn<int>(
    'discogs_release_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> genres =
      GeneratedColumn<String>(
        'genres',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($CachedReleasesTable.$convertergenres);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> styles =
      GeneratedColumn<String>(
        'styles',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($CachedReleasesTable.$converterstyles);
  @override
  late final GeneratedColumnWithTypeConverter<List<ReleaseTrack>, String>
  tracklist = GeneratedColumn<String>(
    'tracklist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<ReleaseTrack>>($CachedReleasesTable.$convertertracklist);
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
  late final GeneratedColumnWithTypeConverter<List<ReleaseIdentifier>, String>
  identifiers =
      GeneratedColumn<String>(
        'identifiers',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<ReleaseIdentifier>>(
        $CachedReleasesTable.$converteridentifiers,
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
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheSourceMeta = const VerificationMeta(
    'cacheSource',
  );
  @override
  late final GeneratedColumn<String> cacheSource = GeneratedColumn<String>(
    'cache_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($CachedReleasesTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    discogsReleaseId,
    artist,
    title,
    label,
    catno,
    format,
    country,
    year,
    genres,
    styles,
    tracklist,
    notes,
    identifiers,
    coverUrl,
    fetchedAt,
    cacheSource,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_releases';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedReleaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('discogs_release_id')) {
      context.handle(
        _discogsReleaseIdMeta,
        discogsReleaseId.isAcceptableOrUnknown(
          data['discogs_release_id']!,
          _discogsReleaseIdMeta,
        ),
      );
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
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('cache_source')) {
      context.handle(
        _cacheSourceMeta,
        cacheSource.isAcceptableOrUnknown(
          data['cache_source']!,
          _cacheSourceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheSourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {discogsReleaseId};
  @override
  CachedReleaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedReleaseRow(
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
      genres: $CachedReleasesTable.$convertergenres.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}genres'],
        )!,
      ),
      styles: $CachedReleasesTable.$converterstyles.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}styles'],
        )!,
      ),
      tracklist: $CachedReleasesTable.$convertertracklist.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tracklist'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      identifiers: $CachedReleasesTable.$converteridentifiers.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}identifiers'],
        )!,
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      cacheSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_source'],
      )!,
      syncStatus: $CachedReleasesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $CachedReleasesTable createAlias(String alias) {
    return $CachedReleasesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertergenres =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterstyles =
      const StringListConverter();
  static TypeConverter<List<ReleaseTrack>, String> $convertertracklist =
      const TrackListConverter();
  static TypeConverter<List<ReleaseIdentifier>, String> $converteridentifiers =
      const IdentifierListConverter();
  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class CachedReleaseRow extends DataClass
    implements Insertable<CachedReleaseRow> {
  final int discogsReleaseId;
  final String artist;
  final String title;
  final String? label;
  final String? catno;
  final String? format;
  final String? country;
  final int? year;
  final List<String> genres;
  final List<String> styles;
  final List<ReleaseTrack> tracklist;
  final String? notes;
  final List<ReleaseIdentifier> identifiers;
  final String? coverUrl;
  final DateTime fetchedAt;
  final String cacheSource;
  final SyncStatus syncStatus;
  const CachedReleaseRow({
    required this.discogsReleaseId,
    required this.artist,
    required this.title,
    this.label,
    this.catno,
    this.format,
    this.country,
    this.year,
    required this.genres,
    required this.styles,
    required this.tracklist,
    this.notes,
    required this.identifiers,
    this.coverUrl,
    required this.fetchedAt,
    required this.cacheSource,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
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
    {
      map['genres'] = Variable<String>(
        $CachedReleasesTable.$convertergenres.toSql(genres),
      );
    }
    {
      map['styles'] = Variable<String>(
        $CachedReleasesTable.$converterstyles.toSql(styles),
      );
    }
    {
      map['tracklist'] = Variable<String>(
        $CachedReleasesTable.$convertertracklist.toSql(tracklist),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['identifiers'] = Variable<String>(
        $CachedReleasesTable.$converteridentifiers.toSql(identifiers),
      );
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['cache_source'] = Variable<String>(cacheSource);
    {
      map['sync_status'] = Variable<String>(
        $CachedReleasesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  CachedReleasesCompanion toCompanion(bool nullToAbsent) {
    return CachedReleasesCompanion(
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
      genres: Value(genres),
      styles: Value(styles),
      tracklist: Value(tracklist),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      identifiers: Value(identifiers),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      fetchedAt: Value(fetchedAt),
      cacheSource: Value(cacheSource),
      syncStatus: Value(syncStatus),
    );
  }

  factory CachedReleaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedReleaseRow(
      discogsReleaseId: serializer.fromJson<int>(json['discogsReleaseId']),
      artist: serializer.fromJson<String>(json['artist']),
      title: serializer.fromJson<String>(json['title']),
      label: serializer.fromJson<String?>(json['label']),
      catno: serializer.fromJson<String?>(json['catno']),
      format: serializer.fromJson<String?>(json['format']),
      country: serializer.fromJson<String?>(json['country']),
      year: serializer.fromJson<int?>(json['year']),
      genres: serializer.fromJson<List<String>>(json['genres']),
      styles: serializer.fromJson<List<String>>(json['styles']),
      tracklist: serializer.fromJson<List<ReleaseTrack>>(json['tracklist']),
      notes: serializer.fromJson<String?>(json['notes']),
      identifiers: serializer.fromJson<List<ReleaseIdentifier>>(
        json['identifiers'],
      ),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      cacheSource: serializer.fromJson<String>(json['cacheSource']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'discogsReleaseId': serializer.toJson<int>(discogsReleaseId),
      'artist': serializer.toJson<String>(artist),
      'title': serializer.toJson<String>(title),
      'label': serializer.toJson<String?>(label),
      'catno': serializer.toJson<String?>(catno),
      'format': serializer.toJson<String?>(format),
      'country': serializer.toJson<String?>(country),
      'year': serializer.toJson<int?>(year),
      'genres': serializer.toJson<List<String>>(genres),
      'styles': serializer.toJson<List<String>>(styles),
      'tracklist': serializer.toJson<List<ReleaseTrack>>(tracklist),
      'notes': serializer.toJson<String?>(notes),
      'identifiers': serializer.toJson<List<ReleaseIdentifier>>(identifiers),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'cacheSource': serializer.toJson<String>(cacheSource),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  CachedReleaseRow copyWith({
    int? discogsReleaseId,
    String? artist,
    String? title,
    Value<String?> label = const Value.absent(),
    Value<String?> catno = const Value.absent(),
    Value<String?> format = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<int?> year = const Value.absent(),
    List<String>? genres,
    List<String>? styles,
    List<ReleaseTrack>? tracklist,
    Value<String?> notes = const Value.absent(),
    List<ReleaseIdentifier>? identifiers,
    Value<String?> coverUrl = const Value.absent(),
    DateTime? fetchedAt,
    String? cacheSource,
    SyncStatus? syncStatus,
  }) => CachedReleaseRow(
    discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
    artist: artist ?? this.artist,
    title: title ?? this.title,
    label: label.present ? label.value : this.label,
    catno: catno.present ? catno.value : this.catno,
    format: format.present ? format.value : this.format,
    country: country.present ? country.value : this.country,
    year: year.present ? year.value : this.year,
    genres: genres ?? this.genres,
    styles: styles ?? this.styles,
    tracklist: tracklist ?? this.tracklist,
    notes: notes.present ? notes.value : this.notes,
    identifiers: identifiers ?? this.identifiers,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    cacheSource: cacheSource ?? this.cacheSource,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  CachedReleaseRow copyWithCompanion(CachedReleasesCompanion data) {
    return CachedReleaseRow(
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
      genres: data.genres.present ? data.genres.value : this.genres,
      styles: data.styles.present ? data.styles.value : this.styles,
      tracklist: data.tracklist.present ? data.tracklist.value : this.tracklist,
      notes: data.notes.present ? data.notes.value : this.notes,
      identifiers: data.identifiers.present
          ? data.identifiers.value
          : this.identifiers,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      cacheSource: data.cacheSource.present
          ? data.cacheSource.value
          : this.cacheSource,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedReleaseRow(')
          ..write('discogsReleaseId: $discogsReleaseId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('label: $label, ')
          ..write('catno: $catno, ')
          ..write('format: $format, ')
          ..write('country: $country, ')
          ..write('year: $year, ')
          ..write('genres: $genres, ')
          ..write('styles: $styles, ')
          ..write('tracklist: $tracklist, ')
          ..write('notes: $notes, ')
          ..write('identifiers: $identifiers, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('cacheSource: $cacheSource, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    discogsReleaseId,
    artist,
    title,
    label,
    catno,
    format,
    country,
    year,
    genres,
    styles,
    tracklist,
    notes,
    identifiers,
    coverUrl,
    fetchedAt,
    cacheSource,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedReleaseRow &&
          other.discogsReleaseId == this.discogsReleaseId &&
          other.artist == this.artist &&
          other.title == this.title &&
          other.label == this.label &&
          other.catno == this.catno &&
          other.format == this.format &&
          other.country == this.country &&
          other.year == this.year &&
          other.genres == this.genres &&
          other.styles == this.styles &&
          other.tracklist == this.tracklist &&
          other.notes == this.notes &&
          other.identifiers == this.identifiers &&
          other.coverUrl == this.coverUrl &&
          other.fetchedAt == this.fetchedAt &&
          other.cacheSource == this.cacheSource &&
          other.syncStatus == this.syncStatus);
}

class CachedReleasesCompanion extends UpdateCompanion<CachedReleaseRow> {
  final Value<int> discogsReleaseId;
  final Value<String> artist;
  final Value<String> title;
  final Value<String?> label;
  final Value<String?> catno;
  final Value<String?> format;
  final Value<String?> country;
  final Value<int?> year;
  final Value<List<String>> genres;
  final Value<List<String>> styles;
  final Value<List<ReleaseTrack>> tracklist;
  final Value<String?> notes;
  final Value<List<ReleaseIdentifier>> identifiers;
  final Value<String?> coverUrl;
  final Value<DateTime> fetchedAt;
  final Value<String> cacheSource;
  final Value<SyncStatus> syncStatus;
  const CachedReleasesCompanion({
    this.discogsReleaseId = const Value.absent(),
    this.artist = const Value.absent(),
    this.title = const Value.absent(),
    this.label = const Value.absent(),
    this.catno = const Value.absent(),
    this.format = const Value.absent(),
    this.country = const Value.absent(),
    this.year = const Value.absent(),
    this.genres = const Value.absent(),
    this.styles = const Value.absent(),
    this.tracklist = const Value.absent(),
    this.notes = const Value.absent(),
    this.identifiers = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.cacheSource = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  CachedReleasesCompanion.insert({
    this.discogsReleaseId = const Value.absent(),
    required String artist,
    required String title,
    this.label = const Value.absent(),
    this.catno = const Value.absent(),
    this.format = const Value.absent(),
    this.country = const Value.absent(),
    this.year = const Value.absent(),
    required List<String> genres,
    required List<String> styles,
    required List<ReleaseTrack> tracklist,
    this.notes = const Value.absent(),
    required List<ReleaseIdentifier> identifiers,
    this.coverUrl = const Value.absent(),
    required DateTime fetchedAt,
    required String cacheSource,
    required SyncStatus syncStatus,
  }) : artist = Value(artist),
       title = Value(title),
       genres = Value(genres),
       styles = Value(styles),
       tracklist = Value(tracklist),
       identifiers = Value(identifiers),
       fetchedAt = Value(fetchedAt),
       cacheSource = Value(cacheSource),
       syncStatus = Value(syncStatus);
  static Insertable<CachedReleaseRow> custom({
    Expression<int>? discogsReleaseId,
    Expression<String>? artist,
    Expression<String>? title,
    Expression<String>? label,
    Expression<String>? catno,
    Expression<String>? format,
    Expression<String>? country,
    Expression<int>? year,
    Expression<String>? genres,
    Expression<String>? styles,
    Expression<String>? tracklist,
    Expression<String>? notes,
    Expression<String>? identifiers,
    Expression<String>? coverUrl,
    Expression<DateTime>? fetchedAt,
    Expression<String>? cacheSource,
    Expression<String>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (discogsReleaseId != null) 'discogs_release_id': discogsReleaseId,
      if (artist != null) 'artist': artist,
      if (title != null) 'title': title,
      if (label != null) 'label': label,
      if (catno != null) 'catno': catno,
      if (format != null) 'format': format,
      if (country != null) 'country': country,
      if (year != null) 'year': year,
      if (genres != null) 'genres': genres,
      if (styles != null) 'styles': styles,
      if (tracklist != null) 'tracklist': tracklist,
      if (notes != null) 'notes': notes,
      if (identifiers != null) 'identifiers': identifiers,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (cacheSource != null) 'cache_source': cacheSource,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  CachedReleasesCompanion copyWith({
    Value<int>? discogsReleaseId,
    Value<String>? artist,
    Value<String>? title,
    Value<String?>? label,
    Value<String?>? catno,
    Value<String?>? format,
    Value<String?>? country,
    Value<int?>? year,
    Value<List<String>>? genres,
    Value<List<String>>? styles,
    Value<List<ReleaseTrack>>? tracklist,
    Value<String?>? notes,
    Value<List<ReleaseIdentifier>>? identifiers,
    Value<String?>? coverUrl,
    Value<DateTime>? fetchedAt,
    Value<String>? cacheSource,
    Value<SyncStatus>? syncStatus,
  }) {
    return CachedReleasesCompanion(
      discogsReleaseId: discogsReleaseId ?? this.discogsReleaseId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      label: label ?? this.label,
      catno: catno ?? this.catno,
      format: format ?? this.format,
      country: country ?? this.country,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      styles: styles ?? this.styles,
      tracklist: tracklist ?? this.tracklist,
      notes: notes ?? this.notes,
      identifiers: identifiers ?? this.identifiers,
      coverUrl: coverUrl ?? this.coverUrl,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      cacheSource: cacheSource ?? this.cacheSource,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
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
    if (genres.present) {
      map['genres'] = Variable<String>(
        $CachedReleasesTable.$convertergenres.toSql(genres.value),
      );
    }
    if (styles.present) {
      map['styles'] = Variable<String>(
        $CachedReleasesTable.$converterstyles.toSql(styles.value),
      );
    }
    if (tracklist.present) {
      map['tracklist'] = Variable<String>(
        $CachedReleasesTable.$convertertracklist.toSql(tracklist.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (identifiers.present) {
      map['identifiers'] = Variable<String>(
        $CachedReleasesTable.$converteridentifiers.toSql(identifiers.value),
      );
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (cacheSource.present) {
      map['cache_source'] = Variable<String>(cacheSource.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $CachedReleasesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedReleasesCompanion(')
          ..write('discogsReleaseId: $discogsReleaseId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('label: $label, ')
          ..write('catno: $catno, ')
          ..write('format: $format, ')
          ..write('country: $country, ')
          ..write('year: $year, ')
          ..write('genres: $genres, ')
          ..write('styles: $styles, ')
          ..write('tracklist: $tracklist, ')
          ..write('notes: $notes, ')
          ..write('identifiers: $identifiers, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('cacheSource: $cacheSource, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $RetryActionsTable extends RetryActions
    with TableInfo<$RetryActionsTable, RetryActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RetryActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RetryActionType, String>
  actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RetryActionType>($RetryActionsTable.$converteractionType);
  @override
  late final GeneratedColumnWithTypeConverter<RetryActionEntityType, String>
  entityType =
      GeneratedColumn<String>(
        'entity_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RetryActionEntityType>(
        $RetryActionsTable.$converterentityType,
      );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _safeErrorMessageMeta = const VerificationMeta(
    'safeErrorMessage',
  );
  @override
  late final GeneratedColumn<String> safeErrorMessage = GeneratedColumn<String>(
    'safe_error_message',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptedAtMeta = const VerificationMeta(
    'lastAttemptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptedAt =
      GeneratedColumn<DateTime>(
        'last_attempted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RetryActionStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RetryActionStatus>($RetryActionsTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actionType,
    entityType,
    entityId,
    safeErrorMessage,
    createdAt,
    lastAttemptedAt,
    attemptCount,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'retry_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RetryActionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('safe_error_message')) {
      context.handle(
        _safeErrorMessageMeta,
        safeErrorMessage.isAcceptableOrUnknown(
          data['safe_error_message']!,
          _safeErrorMessageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_safeErrorMessageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempted_at')) {
      context.handle(
        _lastAttemptedAtMeta,
        lastAttemptedAt.isAcceptableOrUnknown(
          data['last_attempted_at']!,
          _lastAttemptedAtMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RetryActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RetryActionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actionType: $RetryActionsTable.$converteractionType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}action_type'],
        )!,
      ),
      entityType: $RetryActionsTable.$converterentityType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}entity_type'],
        )!,
      ),
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      safeErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}safe_error_message'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempted_at'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      status: $RetryActionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $RetryActionsTable createAlias(String alias) {
    return $RetryActionsTable(attachedDatabase, alias);
  }

  static TypeConverter<RetryActionType, String> $converteractionType =
      const RetryActionTypeConverter();
  static TypeConverter<RetryActionEntityType, String> $converterentityType =
      const RetryActionEntityTypeConverter();
  static TypeConverter<RetryActionStatus, String> $converterstatus =
      const RetryActionStatusConverter();
}

class RetryActionRow extends DataClass implements Insertable<RetryActionRow> {
  final String id;
  final RetryActionType actionType;
  final RetryActionEntityType entityType;
  final String entityId;
  final String safeErrorMessage;
  final DateTime createdAt;
  final DateTime? lastAttemptedAt;
  final int attemptCount;
  final RetryActionStatus status;
  const RetryActionRow({
    required this.id,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.safeErrorMessage,
    required this.createdAt,
    this.lastAttemptedAt,
    required this.attemptCount,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['action_type'] = Variable<String>(
        $RetryActionsTable.$converteractionType.toSql(actionType),
      );
    }
    {
      map['entity_type'] = Variable<String>(
        $RetryActionsTable.$converterentityType.toSql(entityType),
      );
    }
    map['entity_id'] = Variable<String>(entityId);
    map['safe_error_message'] = Variable<String>(safeErrorMessage);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptedAt != null) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    {
      map['status'] = Variable<String>(
        $RetryActionsTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  RetryActionsCompanion toCompanion(bool nullToAbsent) {
    return RetryActionsCompanion(
      id: Value(id),
      actionType: Value(actionType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      safeErrorMessage: Value(safeErrorMessage),
      createdAt: Value(createdAt),
      lastAttemptedAt: lastAttemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptedAt),
      attemptCount: Value(attemptCount),
      status: Value(status),
    );
  }

  factory RetryActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RetryActionRow(
      id: serializer.fromJson<String>(json['id']),
      actionType: serializer.fromJson<RetryActionType>(json['actionType']),
      entityType: serializer.fromJson<RetryActionEntityType>(
        json['entityType'],
      ),
      entityId: serializer.fromJson<String>(json['entityId']),
      safeErrorMessage: serializer.fromJson<String>(json['safeErrorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptedAt: serializer.fromJson<DateTime?>(json['lastAttemptedAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      status: serializer.fromJson<RetryActionStatus>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actionType': serializer.toJson<RetryActionType>(actionType),
      'entityType': serializer.toJson<RetryActionEntityType>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'safeErrorMessage': serializer.toJson<String>(safeErrorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptedAt': serializer.toJson<DateTime?>(lastAttemptedAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'status': serializer.toJson<RetryActionStatus>(status),
    };
  }

  RetryActionRow copyWith({
    String? id,
    RetryActionType? actionType,
    RetryActionEntityType? entityType,
    String? entityId,
    String? safeErrorMessage,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptedAt = const Value.absent(),
    int? attemptCount,
    RetryActionStatus? status,
  }) => RetryActionRow(
    id: id ?? this.id,
    actionType: actionType ?? this.actionType,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    safeErrorMessage: safeErrorMessage ?? this.safeErrorMessage,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptedAt: lastAttemptedAt.present
        ? lastAttemptedAt.value
        : this.lastAttemptedAt,
    attemptCount: attemptCount ?? this.attemptCount,
    status: status ?? this.status,
  );
  RetryActionRow copyWithCompanion(RetryActionsCompanion data) {
    return RetryActionRow(
      id: data.id.present ? data.id.value : this.id,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      safeErrorMessage: data.safeErrorMessage.present
          ? data.safeErrorMessage.value
          : this.safeErrorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptedAt: data.lastAttemptedAt.present
          ? data.lastAttemptedAt.value
          : this.lastAttemptedAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RetryActionRow(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('safeErrorMessage: $safeErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptedAt: $lastAttemptedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionType,
    entityType,
    entityId,
    safeErrorMessage,
    createdAt,
    lastAttemptedAt,
    attemptCount,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RetryActionRow &&
          other.id == this.id &&
          other.actionType == this.actionType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.safeErrorMessage == this.safeErrorMessage &&
          other.createdAt == this.createdAt &&
          other.lastAttemptedAt == this.lastAttemptedAt &&
          other.attemptCount == this.attemptCount &&
          other.status == this.status);
}

class RetryActionsCompanion extends UpdateCompanion<RetryActionRow> {
  final Value<String> id;
  final Value<RetryActionType> actionType;
  final Value<RetryActionEntityType> entityType;
  final Value<String> entityId;
  final Value<String> safeErrorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptedAt;
  final Value<int> attemptCount;
  final Value<RetryActionStatus> status;
  final Value<int> rowid;
  const RetryActionsCompanion({
    this.id = const Value.absent(),
    this.actionType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.safeErrorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RetryActionsCompanion.insert({
    required String id,
    required RetryActionType actionType,
    required RetryActionEntityType entityType,
    required String entityId,
    required String safeErrorMessage,
    required DateTime createdAt,
    this.lastAttemptedAt = const Value.absent(),
    required int attemptCount,
    required RetryActionStatus status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       actionType = Value(actionType),
       entityType = Value(entityType),
       entityId = Value(entityId),
       safeErrorMessage = Value(safeErrorMessage),
       createdAt = Value(createdAt),
       attemptCount = Value(attemptCount),
       status = Value(status);
  static Insertable<RetryActionRow> custom({
    Expression<String>? id,
    Expression<String>? actionType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? safeErrorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptedAt,
    Expression<int>? attemptCount,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionType != null) 'action_type': actionType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (safeErrorMessage != null) 'safe_error_message': safeErrorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptedAt != null) 'last_attempted_at': lastAttemptedAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RetryActionsCompanion copyWith({
    Value<String>? id,
    Value<RetryActionType>? actionType,
    Value<RetryActionEntityType>? entityType,
    Value<String>? entityId,
    Value<String>? safeErrorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptedAt,
    Value<int>? attemptCount,
    Value<RetryActionStatus>? status,
    Value<int>? rowid,
  }) {
    return RetryActionsCompanion(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      safeErrorMessage: safeErrorMessage ?? this.safeErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(
        $RetryActionsTable.$converteractionType.toSql(actionType.value),
      );
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(
        $RetryActionsTable.$converterentityType.toSql(entityType.value),
      );
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (safeErrorMessage.present) {
      map['safe_error_message'] = Variable<String>(safeErrorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptedAt.present) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $RetryActionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RetryActionsCompanion(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('safeErrorMessage: $safeErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptedAt: $lastAttemptedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportExportJobsTable extends ImportExportJobs
    with TableInfo<$ImportExportJobsTable, ImportExportJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportExportJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ImportExportJobType, String>
  jobType =
      GeneratedColumn<String>(
        'job_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ImportExportJobType>(
        $ImportExportJobsTable.$converterjobType,
      );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ImportExportStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ImportExportStatus>($ImportExportJobsTable.$converterstatus);
  static const VerificationMeta _totalItemsMeta = const VerificationMeta(
    'totalItems',
  );
  @override
  late final GeneratedColumn<int> totalItems = GeneratedColumn<int>(
    'total_items',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validItemsMeta = const VerificationMeta(
    'validItems',
  );
  @override
  late final GeneratedColumn<int> validItems = GeneratedColumn<int>(
    'valid_items',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skippedItemsMeta = const VerificationMeta(
    'skippedItems',
  );
  @override
  late final GeneratedColumn<int> skippedItems = GeneratedColumn<int>(
    'skipped_items',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failedItemsMeta = const VerificationMeta(
    'failedItems',
  );
  @override
  late final GeneratedColumn<int> failedItems = GeneratedColumn<int>(
    'failed_items',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _safeErrorMessageMeta = const VerificationMeta(
    'safeErrorMessage',
  );
  @override
  late final GeneratedColumn<String> safeErrorMessage = GeneratedColumn<String>(
    'safe_error_message',
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
    jobType,
    source,
    target,
    status,
    totalItems,
    validItems,
    skippedItems,
    failedItems,
    safeErrorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_export_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportExportJobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('total_items')) {
      context.handle(
        _totalItemsMeta,
        totalItems.isAcceptableOrUnknown(data['total_items']!, _totalItemsMeta),
      );
    }
    if (data.containsKey('valid_items')) {
      context.handle(
        _validItemsMeta,
        validItems.isAcceptableOrUnknown(data['valid_items']!, _validItemsMeta),
      );
    }
    if (data.containsKey('skipped_items')) {
      context.handle(
        _skippedItemsMeta,
        skippedItems.isAcceptableOrUnknown(
          data['skipped_items']!,
          _skippedItemsMeta,
        ),
      );
    }
    if (data.containsKey('failed_items')) {
      context.handle(
        _failedItemsMeta,
        failedItems.isAcceptableOrUnknown(
          data['failed_items']!,
          _failedItemsMeta,
        ),
      );
    }
    if (data.containsKey('safe_error_message')) {
      context.handle(
        _safeErrorMessageMeta,
        safeErrorMessage.isAcceptableOrUnknown(
          data['safe_error_message']!,
          _safeErrorMessageMeta,
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
  ImportExportJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportExportJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jobType: $ImportExportJobsTable.$converterjobType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}job_type'],
        )!,
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      )!,
      status: $ImportExportJobsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      totalItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_items'],
      ),
      validItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valid_items'],
      ),
      skippedItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped_items'],
      ),
      failedItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_items'],
      ),
      safeErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}safe_error_message'],
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
  $ImportExportJobsTable createAlias(String alias) {
    return $ImportExportJobsTable(attachedDatabase, alias);
  }

  static TypeConverter<ImportExportJobType, String> $converterjobType =
      const ImportExportJobTypeConverter();
  static TypeConverter<ImportExportStatus, String> $converterstatus =
      const ImportExportStatusConverter();
}

class ImportExportJobRow extends DataClass
    implements Insertable<ImportExportJobRow> {
  final String id;
  final ImportExportJobType jobType;
  final String source;
  final String target;
  final ImportExportStatus status;
  final int? totalItems;
  final int? validItems;
  final int? skippedItems;
  final int? failedItems;
  final String? safeErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ImportExportJobRow({
    required this.id,
    required this.jobType,
    required this.source,
    required this.target,
    required this.status,
    this.totalItems,
    this.validItems,
    this.skippedItems,
    this.failedItems,
    this.safeErrorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['job_type'] = Variable<String>(
        $ImportExportJobsTable.$converterjobType.toSql(jobType),
      );
    }
    map['source'] = Variable<String>(source);
    map['target'] = Variable<String>(target);
    {
      map['status'] = Variable<String>(
        $ImportExportJobsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || totalItems != null) {
      map['total_items'] = Variable<int>(totalItems);
    }
    if (!nullToAbsent || validItems != null) {
      map['valid_items'] = Variable<int>(validItems);
    }
    if (!nullToAbsent || skippedItems != null) {
      map['skipped_items'] = Variable<int>(skippedItems);
    }
    if (!nullToAbsent || failedItems != null) {
      map['failed_items'] = Variable<int>(failedItems);
    }
    if (!nullToAbsent || safeErrorMessage != null) {
      map['safe_error_message'] = Variable<String>(safeErrorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ImportExportJobsCompanion toCompanion(bool nullToAbsent) {
    return ImportExportJobsCompanion(
      id: Value(id),
      jobType: Value(jobType),
      source: Value(source),
      target: Value(target),
      status: Value(status),
      totalItems: totalItems == null && nullToAbsent
          ? const Value.absent()
          : Value(totalItems),
      validItems: validItems == null && nullToAbsent
          ? const Value.absent()
          : Value(validItems),
      skippedItems: skippedItems == null && nullToAbsent
          ? const Value.absent()
          : Value(skippedItems),
      failedItems: failedItems == null && nullToAbsent
          ? const Value.absent()
          : Value(failedItems),
      safeErrorMessage: safeErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(safeErrorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ImportExportJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportExportJobRow(
      id: serializer.fromJson<String>(json['id']),
      jobType: serializer.fromJson<ImportExportJobType>(json['jobType']),
      source: serializer.fromJson<String>(json['source']),
      target: serializer.fromJson<String>(json['target']),
      status: serializer.fromJson<ImportExportStatus>(json['status']),
      totalItems: serializer.fromJson<int?>(json['totalItems']),
      validItems: serializer.fromJson<int?>(json['validItems']),
      skippedItems: serializer.fromJson<int?>(json['skippedItems']),
      failedItems: serializer.fromJson<int?>(json['failedItems']),
      safeErrorMessage: serializer.fromJson<String?>(json['safeErrorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobType': serializer.toJson<ImportExportJobType>(jobType),
      'source': serializer.toJson<String>(source),
      'target': serializer.toJson<String>(target),
      'status': serializer.toJson<ImportExportStatus>(status),
      'totalItems': serializer.toJson<int?>(totalItems),
      'validItems': serializer.toJson<int?>(validItems),
      'skippedItems': serializer.toJson<int?>(skippedItems),
      'failedItems': serializer.toJson<int?>(failedItems),
      'safeErrorMessage': serializer.toJson<String?>(safeErrorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ImportExportJobRow copyWith({
    String? id,
    ImportExportJobType? jobType,
    String? source,
    String? target,
    ImportExportStatus? status,
    Value<int?> totalItems = const Value.absent(),
    Value<int?> validItems = const Value.absent(),
    Value<int?> skippedItems = const Value.absent(),
    Value<int?> failedItems = const Value.absent(),
    Value<String?> safeErrorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ImportExportJobRow(
    id: id ?? this.id,
    jobType: jobType ?? this.jobType,
    source: source ?? this.source,
    target: target ?? this.target,
    status: status ?? this.status,
    totalItems: totalItems.present ? totalItems.value : this.totalItems,
    validItems: validItems.present ? validItems.value : this.validItems,
    skippedItems: skippedItems.present ? skippedItems.value : this.skippedItems,
    failedItems: failedItems.present ? failedItems.value : this.failedItems,
    safeErrorMessage: safeErrorMessage.present
        ? safeErrorMessage.value
        : this.safeErrorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ImportExportJobRow copyWithCompanion(ImportExportJobsCompanion data) {
    return ImportExportJobRow(
      id: data.id.present ? data.id.value : this.id,
      jobType: data.jobType.present ? data.jobType.value : this.jobType,
      source: data.source.present ? data.source.value : this.source,
      target: data.target.present ? data.target.value : this.target,
      status: data.status.present ? data.status.value : this.status,
      totalItems: data.totalItems.present
          ? data.totalItems.value
          : this.totalItems,
      validItems: data.validItems.present
          ? data.validItems.value
          : this.validItems,
      skippedItems: data.skippedItems.present
          ? data.skippedItems.value
          : this.skippedItems,
      failedItems: data.failedItems.present
          ? data.failedItems.value
          : this.failedItems,
      safeErrorMessage: data.safeErrorMessage.present
          ? data.safeErrorMessage.value
          : this.safeErrorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportExportJobRow(')
          ..write('id: $id, ')
          ..write('jobType: $jobType, ')
          ..write('source: $source, ')
          ..write('target: $target, ')
          ..write('status: $status, ')
          ..write('totalItems: $totalItems, ')
          ..write('validItems: $validItems, ')
          ..write('skippedItems: $skippedItems, ')
          ..write('failedItems: $failedItems, ')
          ..write('safeErrorMessage: $safeErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jobType,
    source,
    target,
    status,
    totalItems,
    validItems,
    skippedItems,
    failedItems,
    safeErrorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportExportJobRow &&
          other.id == this.id &&
          other.jobType == this.jobType &&
          other.source == this.source &&
          other.target == this.target &&
          other.status == this.status &&
          other.totalItems == this.totalItems &&
          other.validItems == this.validItems &&
          other.skippedItems == this.skippedItems &&
          other.failedItems == this.failedItems &&
          other.safeErrorMessage == this.safeErrorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ImportExportJobsCompanion extends UpdateCompanion<ImportExportJobRow> {
  final Value<String> id;
  final Value<ImportExportJobType> jobType;
  final Value<String> source;
  final Value<String> target;
  final Value<ImportExportStatus> status;
  final Value<int?> totalItems;
  final Value<int?> validItems;
  final Value<int?> skippedItems;
  final Value<int?> failedItems;
  final Value<String?> safeErrorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ImportExportJobsCompanion({
    this.id = const Value.absent(),
    this.jobType = const Value.absent(),
    this.source = const Value.absent(),
    this.target = const Value.absent(),
    this.status = const Value.absent(),
    this.totalItems = const Value.absent(),
    this.validItems = const Value.absent(),
    this.skippedItems = const Value.absent(),
    this.failedItems = const Value.absent(),
    this.safeErrorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportExportJobsCompanion.insert({
    required String id,
    required ImportExportJobType jobType,
    required String source,
    required String target,
    required ImportExportStatus status,
    this.totalItems = const Value.absent(),
    this.validItems = const Value.absent(),
    this.skippedItems = const Value.absent(),
    this.failedItems = const Value.absent(),
    this.safeErrorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       jobType = Value(jobType),
       source = Value(source),
       target = Value(target),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ImportExportJobRow> custom({
    Expression<String>? id,
    Expression<String>? jobType,
    Expression<String>? source,
    Expression<String>? target,
    Expression<String>? status,
    Expression<int>? totalItems,
    Expression<int>? validItems,
    Expression<int>? skippedItems,
    Expression<int>? failedItems,
    Expression<String>? safeErrorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobType != null) 'job_type': jobType,
      if (source != null) 'source': source,
      if (target != null) 'target': target,
      if (status != null) 'status': status,
      if (totalItems != null) 'total_items': totalItems,
      if (validItems != null) 'valid_items': validItems,
      if (skippedItems != null) 'skipped_items': skippedItems,
      if (failedItems != null) 'failed_items': failedItems,
      if (safeErrorMessage != null) 'safe_error_message': safeErrorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportExportJobsCompanion copyWith({
    Value<String>? id,
    Value<ImportExportJobType>? jobType,
    Value<String>? source,
    Value<String>? target,
    Value<ImportExportStatus>? status,
    Value<int?>? totalItems,
    Value<int?>? validItems,
    Value<int?>? skippedItems,
    Value<int?>? failedItems,
    Value<String?>? safeErrorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ImportExportJobsCompanion(
      id: id ?? this.id,
      jobType: jobType ?? this.jobType,
      source: source ?? this.source,
      target: target ?? this.target,
      status: status ?? this.status,
      totalItems: totalItems ?? this.totalItems,
      validItems: validItems ?? this.validItems,
      skippedItems: skippedItems ?? this.skippedItems,
      failedItems: failedItems ?? this.failedItems,
      safeErrorMessage: safeErrorMessage ?? this.safeErrorMessage,
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
    if (jobType.present) {
      map['job_type'] = Variable<String>(
        $ImportExportJobsTable.$converterjobType.toSql(jobType.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ImportExportJobsTable.$converterstatus.toSql(status.value),
      );
    }
    if (totalItems.present) {
      map['total_items'] = Variable<int>(totalItems.value);
    }
    if (validItems.present) {
      map['valid_items'] = Variable<int>(validItems.value);
    }
    if (skippedItems.present) {
      map['skipped_items'] = Variable<int>(skippedItems.value);
    }
    if (failedItems.present) {
      map['failed_items'] = Variable<int>(failedItems.value);
    }
    if (safeErrorMessage.present) {
      map['safe_error_message'] = Variable<String>(safeErrorMessage.value);
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
    return (StringBuffer('ImportExportJobsCompanion(')
          ..write('id: $id, ')
          ..write('jobType: $jobType, ')
          ..write('source: $source, ')
          ..write('target: $target, ')
          ..write('status: $status, ')
          ..write('totalItems: $totalItems, ')
          ..write('validItems: $validItems, ')
          ..write('skippedItems: $skippedItems, ')
          ..write('failedItems: $failedItems, ')
          ..write('safeErrorMessage: $safeErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportExportRowResultsTable extends ImportExportRowResults
    with TableInfo<$ImportExportRowResultsTable, ImportExportRowResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportExportRowResultsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultTypeMeta = const VerificationMeta(
    'resultType',
  );
  @override
  late final GeneratedColumn<String> resultType = GeneratedColumn<String>(
    'result_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIndexMeta = const VerificationMeta(
    'rowIndex',
  );
  @override
  late final GeneratedColumn<int> rowIndex = GeneratedColumn<int>(
    'row_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _safeErrorMessageMeta = const VerificationMeta(
    'safeErrorMessage',
  );
  @override
  late final GeneratedColumn<String> safeErrorMessage = GeneratedColumn<String>(
    'safe_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    resultType,
    rowIndex,
    description,
    reason,
    safeErrorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_export_row_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportExportRowResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('result_type')) {
      context.handle(
        _resultTypeMeta,
        resultType.isAcceptableOrUnknown(data['result_type']!, _resultTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_resultTypeMeta);
    }
    if (data.containsKey('row_index')) {
      context.handle(
        _rowIndexMeta,
        rowIndex.isAcceptableOrUnknown(data['row_index']!, _rowIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIndexMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('safe_error_message')) {
      context.handle(
        _safeErrorMessageMeta,
        safeErrorMessage.isAcceptableOrUnknown(
          data['safe_error_message']!,
          _safeErrorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportExportRowResultRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportExportRowResultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      resultType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_type'],
      )!,
      rowIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_index'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      safeErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}safe_error_message'],
      ),
    );
  }

  @override
  $ImportExportRowResultsTable createAlias(String alias) {
    return $ImportExportRowResultsTable(attachedDatabase, alias);
  }
}

class ImportExportRowResultRow extends DataClass
    implements Insertable<ImportExportRowResultRow> {
  final int id;
  final String jobId;
  final String resultType;
  final int rowIndex;
  final String? description;
  final String? reason;
  final String? safeErrorMessage;
  const ImportExportRowResultRow({
    required this.id,
    required this.jobId,
    required this.resultType,
    required this.rowIndex,
    this.description,
    this.reason,
    this.safeErrorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_id'] = Variable<String>(jobId);
    map['result_type'] = Variable<String>(resultType);
    map['row_index'] = Variable<int>(rowIndex);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || safeErrorMessage != null) {
      map['safe_error_message'] = Variable<String>(safeErrorMessage);
    }
    return map;
  }

  ImportExportRowResultsCompanion toCompanion(bool nullToAbsent) {
    return ImportExportRowResultsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      resultType: Value(resultType),
      rowIndex: Value(rowIndex),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      safeErrorMessage: safeErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(safeErrorMessage),
    );
  }

  factory ImportExportRowResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportExportRowResultRow(
      id: serializer.fromJson<int>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      resultType: serializer.fromJson<String>(json['resultType']),
      rowIndex: serializer.fromJson<int>(json['rowIndex']),
      description: serializer.fromJson<String?>(json['description']),
      reason: serializer.fromJson<String?>(json['reason']),
      safeErrorMessage: serializer.fromJson<String?>(json['safeErrorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobId': serializer.toJson<String>(jobId),
      'resultType': serializer.toJson<String>(resultType),
      'rowIndex': serializer.toJson<int>(rowIndex),
      'description': serializer.toJson<String?>(description),
      'reason': serializer.toJson<String?>(reason),
      'safeErrorMessage': serializer.toJson<String?>(safeErrorMessage),
    };
  }

  ImportExportRowResultRow copyWith({
    int? id,
    String? jobId,
    String? resultType,
    int? rowIndex,
    Value<String?> description = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    Value<String?> safeErrorMessage = const Value.absent(),
  }) => ImportExportRowResultRow(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    resultType: resultType ?? this.resultType,
    rowIndex: rowIndex ?? this.rowIndex,
    description: description.present ? description.value : this.description,
    reason: reason.present ? reason.value : this.reason,
    safeErrorMessage: safeErrorMessage.present
        ? safeErrorMessage.value
        : this.safeErrorMessage,
  );
  ImportExportRowResultRow copyWithCompanion(
    ImportExportRowResultsCompanion data,
  ) {
    return ImportExportRowResultRow(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      resultType: data.resultType.present
          ? data.resultType.value
          : this.resultType,
      rowIndex: data.rowIndex.present ? data.rowIndex.value : this.rowIndex,
      description: data.description.present
          ? data.description.value
          : this.description,
      reason: data.reason.present ? data.reason.value : this.reason,
      safeErrorMessage: data.safeErrorMessage.present
          ? data.safeErrorMessage.value
          : this.safeErrorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportExportRowResultRow(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('resultType: $resultType, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('description: $description, ')
          ..write('reason: $reason, ')
          ..write('safeErrorMessage: $safeErrorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jobId,
    resultType,
    rowIndex,
    description,
    reason,
    safeErrorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportExportRowResultRow &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.resultType == this.resultType &&
          other.rowIndex == this.rowIndex &&
          other.description == this.description &&
          other.reason == this.reason &&
          other.safeErrorMessage == this.safeErrorMessage);
}

class ImportExportRowResultsCompanion
    extends UpdateCompanion<ImportExportRowResultRow> {
  final Value<int> id;
  final Value<String> jobId;
  final Value<String> resultType;
  final Value<int> rowIndex;
  final Value<String?> description;
  final Value<String?> reason;
  final Value<String?> safeErrorMessage;
  const ImportExportRowResultsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.resultType = const Value.absent(),
    this.rowIndex = const Value.absent(),
    this.description = const Value.absent(),
    this.reason = const Value.absent(),
    this.safeErrorMessage = const Value.absent(),
  });
  ImportExportRowResultsCompanion.insert({
    this.id = const Value.absent(),
    required String jobId,
    required String resultType,
    required int rowIndex,
    this.description = const Value.absent(),
    this.reason = const Value.absent(),
    this.safeErrorMessage = const Value.absent(),
  }) : jobId = Value(jobId),
       resultType = Value(resultType),
       rowIndex = Value(rowIndex);
  static Insertable<ImportExportRowResultRow> custom({
    Expression<int>? id,
    Expression<String>? jobId,
    Expression<String>? resultType,
    Expression<int>? rowIndex,
    Expression<String>? description,
    Expression<String>? reason,
    Expression<String>? safeErrorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (resultType != null) 'result_type': resultType,
      if (rowIndex != null) 'row_index': rowIndex,
      if (description != null) 'description': description,
      if (reason != null) 'reason': reason,
      if (safeErrorMessage != null) 'safe_error_message': safeErrorMessage,
    });
  }

  ImportExportRowResultsCompanion copyWith({
    Value<int>? id,
    Value<String>? jobId,
    Value<String>? resultType,
    Value<int>? rowIndex,
    Value<String?>? description,
    Value<String?>? reason,
    Value<String?>? safeErrorMessage,
  }) {
    return ImportExportRowResultsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      resultType: resultType ?? this.resultType,
      rowIndex: rowIndex ?? this.rowIndex,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      safeErrorMessage: safeErrorMessage ?? this.safeErrorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (resultType.present) {
      map['result_type'] = Variable<String>(resultType.value);
    }
    if (rowIndex.present) {
      map['row_index'] = Variable<int>(rowIndex.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (safeErrorMessage.present) {
      map['safe_error_message'] = Variable<String>(safeErrorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportExportRowResultsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('resultType: $resultType, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('description: $description, ')
          ..write('reason: $reason, ')
          ..write('safeErrorMessage: $safeErrorMessage')
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
  late final $CachedReleasesTable cachedReleases = $CachedReleasesTable(this);
  late final $RetryActionsTable retryActions = $RetryActionsTable(this);
  late final $ImportExportJobsTable importExportJobs = $ImportExportJobsTable(
    this,
  );
  late final $ImportExportRowResultsTable importExportRowResults =
      $ImportExportRowResultsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    collectionItems,
    wishlistItems,
    cachedReleases,
    retryActions,
    importExportJobs,
    importExportRowResults,
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
      Value<SyncStatus?> syncStatus,
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
      Value<SyncStatus?> syncStatus,
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

  ColumnWithTypeConverterFilters<SyncStatus?, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
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

  GeneratedColumnWithTypeConverter<SyncStatus?, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
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
                Value<SyncStatus?> syncStatus = const Value.absent(),
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
                syncStatus: syncStatus,
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
                Value<SyncStatus?> syncStatus = const Value.absent(),
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
                syncStatus: syncStatus,
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
      Value<SyncStatus?> syncStatus,
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
      Value<SyncStatus?> syncStatus,
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

  ColumnWithTypeConverterFilters<SyncStatus?, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
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

  GeneratedColumnWithTypeConverter<SyncStatus?, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

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
                Value<SyncStatus?> syncStatus = const Value.absent(),
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
                syncStatus: syncStatus,
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
                Value<SyncStatus?> syncStatus = const Value.absent(),
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
                syncStatus: syncStatus,
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
typedef $$CachedReleasesTableCreateCompanionBuilder =
    CachedReleasesCompanion Function({
      Value<int> discogsReleaseId,
      required String artist,
      required String title,
      Value<String?> label,
      Value<String?> catno,
      Value<String?> format,
      Value<String?> country,
      Value<int?> year,
      required List<String> genres,
      required List<String> styles,
      required List<ReleaseTrack> tracklist,
      Value<String?> notes,
      required List<ReleaseIdentifier> identifiers,
      Value<String?> coverUrl,
      required DateTime fetchedAt,
      required String cacheSource,
      required SyncStatus syncStatus,
    });
typedef $$CachedReleasesTableUpdateCompanionBuilder =
    CachedReleasesCompanion Function({
      Value<int> discogsReleaseId,
      Value<String> artist,
      Value<String> title,
      Value<String?> label,
      Value<String?> catno,
      Value<String?> format,
      Value<String?> country,
      Value<int?> year,
      Value<List<String>> genres,
      Value<List<String>> styles,
      Value<List<ReleaseTrack>> tracklist,
      Value<String?> notes,
      Value<List<ReleaseIdentifier>> identifiers,
      Value<String?> coverUrl,
      Value<DateTime> fetchedAt,
      Value<String> cacheSource,
      Value<SyncStatus> syncStatus,
    });

class $$CachedReleasesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedReleasesTable> {
  $$CachedReleasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get styles => $composableBuilder(
    column: $table.styles,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<ReleaseTrack>, List<ReleaseTrack>, String>
  get tracklist => $composableBuilder(
    column: $table.tracklist,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<ReleaseIdentifier>,
    List<ReleaseIdentifier>,
    String
  >
  get identifiers => $composableBuilder(
    column: $table.identifiers,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheSource => $composableBuilder(
    column: $table.cacheSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$CachedReleasesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedReleasesTable> {
  $$CachedReleasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get styles => $composableBuilder(
    column: $table.styles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tracklist => $composableBuilder(
    column: $table.tracklist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identifiers => $composableBuilder(
    column: $table.identifiers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheSource => $composableBuilder(
    column: $table.cacheSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedReleasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedReleasesTable> {
  $$CachedReleasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  GeneratedColumnWithTypeConverter<List<String>, String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get styles =>
      $composableBuilder(column: $table.styles, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<ReleaseTrack>, String> get tracklist =>
      $composableBuilder(column: $table.tracklist, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<ReleaseIdentifier>, String>
  get identifiers => $composableBuilder(
    column: $table.identifiers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get cacheSource => $composableBuilder(
    column: $table.cacheSource,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$CachedReleasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedReleasesTable,
          CachedReleaseRow,
          $$CachedReleasesTableFilterComposer,
          $$CachedReleasesTableOrderingComposer,
          $$CachedReleasesTableAnnotationComposer,
          $$CachedReleasesTableCreateCompanionBuilder,
          $$CachedReleasesTableUpdateCompanionBuilder,
          (
            CachedReleaseRow,
            BaseReferences<
              _$AppDatabase,
              $CachedReleasesTable,
              CachedReleaseRow
            >,
          ),
          CachedReleaseRow,
          PrefetchHooks Function()
        > {
  $$CachedReleasesTableTableManager(
    _$AppDatabase db,
    $CachedReleasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedReleasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedReleasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedReleasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> discogsReleaseId = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> catno = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<List<String>> genres = const Value.absent(),
                Value<List<String>> styles = const Value.absent(),
                Value<List<ReleaseTrack>> tracklist = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<List<ReleaseIdentifier>> identifiers =
                    const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<String> cacheSource = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
              }) => CachedReleasesCompanion(
                discogsReleaseId: discogsReleaseId,
                artist: artist,
                title: title,
                label: label,
                catno: catno,
                format: format,
                country: country,
                year: year,
                genres: genres,
                styles: styles,
                tracklist: tracklist,
                notes: notes,
                identifiers: identifiers,
                coverUrl: coverUrl,
                fetchedAt: fetchedAt,
                cacheSource: cacheSource,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> discogsReleaseId = const Value.absent(),
                required String artist,
                required String title,
                Value<String?> label = const Value.absent(),
                Value<String?> catno = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<int?> year = const Value.absent(),
                required List<String> genres,
                required List<String> styles,
                required List<ReleaseTrack> tracklist,
                Value<String?> notes = const Value.absent(),
                required List<ReleaseIdentifier> identifiers,
                Value<String?> coverUrl = const Value.absent(),
                required DateTime fetchedAt,
                required String cacheSource,
                required SyncStatus syncStatus,
              }) => CachedReleasesCompanion.insert(
                discogsReleaseId: discogsReleaseId,
                artist: artist,
                title: title,
                label: label,
                catno: catno,
                format: format,
                country: country,
                year: year,
                genres: genres,
                styles: styles,
                tracklist: tracklist,
                notes: notes,
                identifiers: identifiers,
                coverUrl: coverUrl,
                fetchedAt: fetchedAt,
                cacheSource: cacheSource,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedReleasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedReleasesTable,
      CachedReleaseRow,
      $$CachedReleasesTableFilterComposer,
      $$CachedReleasesTableOrderingComposer,
      $$CachedReleasesTableAnnotationComposer,
      $$CachedReleasesTableCreateCompanionBuilder,
      $$CachedReleasesTableUpdateCompanionBuilder,
      (
        CachedReleaseRow,
        BaseReferences<_$AppDatabase, $CachedReleasesTable, CachedReleaseRow>,
      ),
      CachedReleaseRow,
      PrefetchHooks Function()
    >;
typedef $$RetryActionsTableCreateCompanionBuilder =
    RetryActionsCompanion Function({
      required String id,
      required RetryActionType actionType,
      required RetryActionEntityType entityType,
      required String entityId,
      required String safeErrorMessage,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptedAt,
      required int attemptCount,
      required RetryActionStatus status,
      Value<int> rowid,
    });
typedef $$RetryActionsTableUpdateCompanionBuilder =
    RetryActionsCompanion Function({
      Value<String> id,
      Value<RetryActionType> actionType,
      Value<RetryActionEntityType> entityType,
      Value<String> entityId,
      Value<String> safeErrorMessage,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptedAt,
      Value<int> attemptCount,
      Value<RetryActionStatus> status,
      Value<int> rowid,
    });

class $$RetryActionsTableFilterComposer
    extends Composer<_$AppDatabase, $RetryActionsTable> {
  $$RetryActionsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<RetryActionType, RetryActionType, String>
  get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    RetryActionEntityType,
    RetryActionEntityType,
    String
  >
  get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RetryActionStatus, RetryActionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$RetryActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RetryActionsTable> {
  $$RetryActionsTableOrderingComposer({
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

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RetryActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RetryActionsTable> {
  $$RetryActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RetryActionType, String> get actionType =>
      $composableBuilder(
        column: $table.actionType,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<RetryActionEntityType, String>
  get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RetryActionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$RetryActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RetryActionsTable,
          RetryActionRow,
          $$RetryActionsTableFilterComposer,
          $$RetryActionsTableOrderingComposer,
          $$RetryActionsTableAnnotationComposer,
          $$RetryActionsTableCreateCompanionBuilder,
          $$RetryActionsTableUpdateCompanionBuilder,
          (
            RetryActionRow,
            BaseReferences<_$AppDatabase, $RetryActionsTable, RetryActionRow>,
          ),
          RetryActionRow,
          PrefetchHooks Function()
        > {
  $$RetryActionsTableTableManager(_$AppDatabase db, $RetryActionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RetryActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RetryActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RetryActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<RetryActionType> actionType = const Value.absent(),
                Value<RetryActionEntityType> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> safeErrorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptedAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<RetryActionStatus> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RetryActionsCompanion(
                id: id,
                actionType: actionType,
                entityType: entityType,
                entityId: entityId,
                safeErrorMessage: safeErrorMessage,
                createdAt: createdAt,
                lastAttemptedAt: lastAttemptedAt,
                attemptCount: attemptCount,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required RetryActionType actionType,
                required RetryActionEntityType entityType,
                required String entityId,
                required String safeErrorMessage,
                required DateTime createdAt,
                Value<DateTime?> lastAttemptedAt = const Value.absent(),
                required int attemptCount,
                required RetryActionStatus status,
                Value<int> rowid = const Value.absent(),
              }) => RetryActionsCompanion.insert(
                id: id,
                actionType: actionType,
                entityType: entityType,
                entityId: entityId,
                safeErrorMessage: safeErrorMessage,
                createdAt: createdAt,
                lastAttemptedAt: lastAttemptedAt,
                attemptCount: attemptCount,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RetryActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RetryActionsTable,
      RetryActionRow,
      $$RetryActionsTableFilterComposer,
      $$RetryActionsTableOrderingComposer,
      $$RetryActionsTableAnnotationComposer,
      $$RetryActionsTableCreateCompanionBuilder,
      $$RetryActionsTableUpdateCompanionBuilder,
      (
        RetryActionRow,
        BaseReferences<_$AppDatabase, $RetryActionsTable, RetryActionRow>,
      ),
      RetryActionRow,
      PrefetchHooks Function()
    >;
typedef $$ImportExportJobsTableCreateCompanionBuilder =
    ImportExportJobsCompanion Function({
      required String id,
      required ImportExportJobType jobType,
      required String source,
      required String target,
      required ImportExportStatus status,
      Value<int?> totalItems,
      Value<int?> validItems,
      Value<int?> skippedItems,
      Value<int?> failedItems,
      Value<String?> safeErrorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ImportExportJobsTableUpdateCompanionBuilder =
    ImportExportJobsCompanion Function({
      Value<String> id,
      Value<ImportExportJobType> jobType,
      Value<String> source,
      Value<String> target,
      Value<ImportExportStatus> status,
      Value<int?> totalItems,
      Value<int?> validItems,
      Value<int?> skippedItems,
      Value<int?> failedItems,
      Value<String?> safeErrorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ImportExportJobsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportExportJobsTable> {
  $$ImportExportJobsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<
    ImportExportJobType,
    ImportExportJobType,
    String
  >
  get jobType => $composableBuilder(
    column: $table.jobType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ImportExportStatus, ImportExportStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get validItems => $composableBuilder(
    column: $table.validItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skippedItems => $composableBuilder(
    column: $table.skippedItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedItems => $composableBuilder(
    column: $table.failedItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
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

class $$ImportExportJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportExportJobsTable> {
  $$ImportExportJobsTableOrderingComposer({
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

  ColumnOrderings<String> get jobType => $composableBuilder(
    column: $table.jobType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get validItems => $composableBuilder(
    column: $table.validItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skippedItems => $composableBuilder(
    column: $table.skippedItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedItems => $composableBuilder(
    column: $table.failedItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
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

class $$ImportExportJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportExportJobsTable> {
  $$ImportExportJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ImportExportJobType, String> get jobType =>
      $composableBuilder(column: $table.jobType, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ImportExportStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => column,
  );

  GeneratedColumn<int> get validItems => $composableBuilder(
    column: $table.validItems,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skippedItems => $composableBuilder(
    column: $table.skippedItems,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedItems => $composableBuilder(
    column: $table.failedItems,
    builder: (column) => column,
  );

  GeneratedColumn<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ImportExportJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportExportJobsTable,
          ImportExportJobRow,
          $$ImportExportJobsTableFilterComposer,
          $$ImportExportJobsTableOrderingComposer,
          $$ImportExportJobsTableAnnotationComposer,
          $$ImportExportJobsTableCreateCompanionBuilder,
          $$ImportExportJobsTableUpdateCompanionBuilder,
          (
            ImportExportJobRow,
            BaseReferences<
              _$AppDatabase,
              $ImportExportJobsTable,
              ImportExportJobRow
            >,
          ),
          ImportExportJobRow,
          PrefetchHooks Function()
        > {
  $$ImportExportJobsTableTableManager(
    _$AppDatabase db,
    $ImportExportJobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportExportJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportExportJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportExportJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<ImportExportJobType> jobType = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> target = const Value.absent(),
                Value<ImportExportStatus> status = const Value.absent(),
                Value<int?> totalItems = const Value.absent(),
                Value<int?> validItems = const Value.absent(),
                Value<int?> skippedItems = const Value.absent(),
                Value<int?> failedItems = const Value.absent(),
                Value<String?> safeErrorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportExportJobsCompanion(
                id: id,
                jobType: jobType,
                source: source,
                target: target,
                status: status,
                totalItems: totalItems,
                validItems: validItems,
                skippedItems: skippedItems,
                failedItems: failedItems,
                safeErrorMessage: safeErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required ImportExportJobType jobType,
                required String source,
                required String target,
                required ImportExportStatus status,
                Value<int?> totalItems = const Value.absent(),
                Value<int?> validItems = const Value.absent(),
                Value<int?> skippedItems = const Value.absent(),
                Value<int?> failedItems = const Value.absent(),
                Value<String?> safeErrorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportExportJobsCompanion.insert(
                id: id,
                jobType: jobType,
                source: source,
                target: target,
                status: status,
                totalItems: totalItems,
                validItems: validItems,
                skippedItems: skippedItems,
                failedItems: failedItems,
                safeErrorMessage: safeErrorMessage,
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

typedef $$ImportExportJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportExportJobsTable,
      ImportExportJobRow,
      $$ImportExportJobsTableFilterComposer,
      $$ImportExportJobsTableOrderingComposer,
      $$ImportExportJobsTableAnnotationComposer,
      $$ImportExportJobsTableCreateCompanionBuilder,
      $$ImportExportJobsTableUpdateCompanionBuilder,
      (
        ImportExportJobRow,
        BaseReferences<
          _$AppDatabase,
          $ImportExportJobsTable,
          ImportExportJobRow
        >,
      ),
      ImportExportJobRow,
      PrefetchHooks Function()
    >;
typedef $$ImportExportRowResultsTableCreateCompanionBuilder =
    ImportExportRowResultsCompanion Function({
      Value<int> id,
      required String jobId,
      required String resultType,
      required int rowIndex,
      Value<String?> description,
      Value<String?> reason,
      Value<String?> safeErrorMessage,
    });
typedef $$ImportExportRowResultsTableUpdateCompanionBuilder =
    ImportExportRowResultsCompanion Function({
      Value<int> id,
      Value<String> jobId,
      Value<String> resultType,
      Value<int> rowIndex,
      Value<String?> description,
      Value<String?> reason,
      Value<String?> safeErrorMessage,
    });

class $$ImportExportRowResultsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportExportRowResultsTable> {
  $$ImportExportRowResultsTableFilterComposer({
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

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultType => $composableBuilder(
    column: $table.resultType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportExportRowResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportExportRowResultsTable> {
  $$ImportExportRowResultsTableOrderingComposer({
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

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultType => $composableBuilder(
    column: $table.resultType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportExportRowResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportExportRowResultsTable> {
  $$ImportExportRowResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get resultType => $composableBuilder(
    column: $table.resultType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowIndex =>
      $composableBuilder(column: $table.rowIndex, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get safeErrorMessage => $composableBuilder(
    column: $table.safeErrorMessage,
    builder: (column) => column,
  );
}

class $$ImportExportRowResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportExportRowResultsTable,
          ImportExportRowResultRow,
          $$ImportExportRowResultsTableFilterComposer,
          $$ImportExportRowResultsTableOrderingComposer,
          $$ImportExportRowResultsTableAnnotationComposer,
          $$ImportExportRowResultsTableCreateCompanionBuilder,
          $$ImportExportRowResultsTableUpdateCompanionBuilder,
          (
            ImportExportRowResultRow,
            BaseReferences<
              _$AppDatabase,
              $ImportExportRowResultsTable,
              ImportExportRowResultRow
            >,
          ),
          ImportExportRowResultRow,
          PrefetchHooks Function()
        > {
  $$ImportExportRowResultsTableTableManager(
    _$AppDatabase db,
    $ImportExportRowResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportExportRowResultsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ImportExportRowResultsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ImportExportRowResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<String> resultType = const Value.absent(),
                Value<int> rowIndex = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> safeErrorMessage = const Value.absent(),
              }) => ImportExportRowResultsCompanion(
                id: id,
                jobId: jobId,
                resultType: resultType,
                rowIndex: rowIndex,
                description: description,
                reason: reason,
                safeErrorMessage: safeErrorMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jobId,
                required String resultType,
                required int rowIndex,
                Value<String?> description = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> safeErrorMessage = const Value.absent(),
              }) => ImportExportRowResultsCompanion.insert(
                id: id,
                jobId: jobId,
                resultType: resultType,
                rowIndex: rowIndex,
                description: description,
                reason: reason,
                safeErrorMessage: safeErrorMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportExportRowResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportExportRowResultsTable,
      ImportExportRowResultRow,
      $$ImportExportRowResultsTableFilterComposer,
      $$ImportExportRowResultsTableOrderingComposer,
      $$ImportExportRowResultsTableAnnotationComposer,
      $$ImportExportRowResultsTableCreateCompanionBuilder,
      $$ImportExportRowResultsTableUpdateCompanionBuilder,
      (
        ImportExportRowResultRow,
        BaseReferences<
          _$AppDatabase,
          $ImportExportRowResultsTable,
          ImportExportRowResultRow
        >,
      ),
      ImportExportRowResultRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CollectionItemsTableTableManager get collectionItems =>
      $$CollectionItemsTableTableManager(_db, _db.collectionItems);
  $$WishlistItemsTableTableManager get wishlistItems =>
      $$WishlistItemsTableTableManager(_db, _db.wishlistItems);
  $$CachedReleasesTableTableManager get cachedReleases =>
      $$CachedReleasesTableTableManager(_db, _db.cachedReleases);
  $$RetryActionsTableTableManager get retryActions =>
      $$RetryActionsTableTableManager(_db, _db.retryActions);
  $$ImportExportJobsTableTableManager get importExportJobs =>
      $$ImportExportJobsTableTableManager(_db, _db.importExportJobs);
  $$ImportExportRowResultsTableTableManager get importExportRowResults =>
      $$ImportExportRowResultsTableTableManager(
        _db,
        _db.importExportRowResults,
      );
}
