import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/collection_item.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/retry_action.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_item.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Type converters
// ---------------------------------------------------------------------------

class RecordConditionConverter extends TypeConverter<RecordCondition, String> {
  const RecordConditionConverter();

  @override
  RecordCondition fromSql(String fromDb) =>
      RecordCondition.values.byName(fromDb);

  @override
  String toSql(RecordCondition value) => value.name;
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class TrackListConverter extends TypeConverter<List<ReleaseTrack>, String> {
  const TrackListConverter();

  @override
  List<ReleaseTrack> fromSql(String fromDb) {
    final list = jsonDecode(fromDb) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return ReleaseTrack(
        position: m['position'] as String? ?? '',
        title: m['title'] as String? ?? '',
        duration: m['duration'] as String? ?? '',
      );
    }).toList();
  }

  @override
  String toSql(List<ReleaseTrack> value) => jsonEncode(
    value
        .map(
          (t) => {
            'position': t.position,
            'title': t.title,
            'duration': t.duration,
          },
        )
        .toList(),
  );
}

class IdentifierListConverter
    extends TypeConverter<List<ReleaseIdentifier>, String> {
  const IdentifierListConverter();

  @override
  List<ReleaseIdentifier> fromSql(String fromDb) {
    final list = jsonDecode(fromDb) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return ReleaseIdentifier(
        type: m['type'] as String? ?? '',
        value: m['value'] as String? ?? '',
      );
    }).toList();
  }

  @override
  String toSql(List<ReleaseIdentifier> value) =>
      jsonEncode(value.map((i) => {'type': i.type, 'value': i.value}).toList());
}

class WishlistPriorityConverter
    extends TypeConverter<WishlistPriority, String> {
  const WishlistPriorityConverter();

  @override
  WishlistPriority fromSql(String fromDb) =>
      WishlistPriority.values.byName(fromDb);

  @override
  String toSql(WishlistPriority value) => value.name;
}

class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const SyncStatusConverter();

  @override
  SyncStatus fromSql(String fromDb) => SyncStatus.values.byName(fromDb);

  @override
  String toSql(SyncStatus value) => value.name;
}

class RetryActionTypeConverter extends TypeConverter<RetryActionType, String> {
  const RetryActionTypeConverter();

  @override
  RetryActionType fromSql(String fromDb) =>
      RetryActionType.values.byName(fromDb);

  @override
  String toSql(RetryActionType value) => value.name;
}

class MusicalKeyConverter extends TypeConverter<MusicalKey, String> {
  const MusicalKeyConverter();

  @override
  MusicalKey fromSql(String fromDb) => MusicalKey.values.byName(fromDb);

  @override
  String toSql(MusicalKey value) => value.name;
}

class RetryActionEntityTypeConverter
    extends TypeConverter<RetryActionEntityType, String> {
  const RetryActionEntityTypeConverter();

  @override
  RetryActionEntityType fromSql(String fromDb) =>
      RetryActionEntityType.values.byName(fromDb);

  @override
  String toSql(RetryActionEntityType value) => value.name;
}

class RetryActionStatusConverter
    extends TypeConverter<RetryActionStatus, String> {
  const RetryActionStatusConverter();

  @override
  RetryActionStatus fromSql(String fromDb) =>
      RetryActionStatus.values.byName(fromDb);

  @override
  String toSql(RetryActionStatus value) => value.name;
}

class ImportExportJobTypeConverter
    extends TypeConverter<ImportExportJobType, String> {
  const ImportExportJobTypeConverter();

  @override
  ImportExportJobType fromSql(String fromDb) =>
      ImportExportJobType.values.byName(fromDb);

  @override
  String toSql(ImportExportJobType value) => value.name;
}

class ImportExportStatusConverter
    extends TypeConverter<ImportExportStatus, String> {
  const ImportExportStatusConverter();

  @override
  ImportExportStatus fromSql(String fromDb) =>
      ImportExportStatus.values.byName(fromDb);

  @override
  String toSql(ImportExportStatus value) => value.name;
}

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

@DataClassName('CollectionRow')
class CollectionItems extends Table {
  TextColumn get id => text()();
  IntColumn get discogsReleaseId => integer()();
  TextColumn get artist => text()();
  TextColumn get title => text()();
  TextColumn get label => text().nullable()();
  TextColumn get catno => text().nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get country => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get mediaCondition =>
      text().map(const RecordConditionConverter())();
  TextColumn get sleeveCondition =>
      text().map(const RecordConditionConverter())();
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().map(const StringListConverter())();
  TextColumn get storageLocation => text().nullable()();
  TextColumn get syncStatus =>
      text().nullable().map(const SyncStatusConverter())();
  IntColumn get discogsInstanceId => integer().nullable()();
  // DJ metadata (US-121) — local only, never synced to Discogs.
  IntColumn get bpm => integer().nullable()();
  TextColumn get musicalKey =>
      text().nullable().map(const MusicalKeyConverter())();
  IntColumn get energyLevel => integer().nullable()();
  TextColumn get gigCrates =>
      text().nullable().map(const StringListConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WishlistRow')
class WishlistItems extends Table {
  TextColumn get id => text()();
  IntColumn get discogsReleaseId => integer()();
  TextColumn get artist => text()();
  TextColumn get title => text()();
  TextColumn get label => text().nullable()();
  TextColumn get catno => text().nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get country => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get coverUrl => text().nullable()();
  RealColumn get targetPrice => real().nullable()();
  TextColumn get priority => text().map(const WishlistPriorityConverter())();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus =>
      text().nullable().map(const SyncStatusConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CachedReleaseRow')
class CachedReleases extends Table {
  IntColumn get discogsReleaseId => integer()();
  TextColumn get artist => text()();
  TextColumn get title => text()();
  TextColumn get label => text().nullable()();
  TextColumn get catno => text().nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get country => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genres => text().map(const StringListConverter())();
  TextColumn get styles => text().map(const StringListConverter())();
  TextColumn get tracklist => text().map(const TrackListConverter())();
  TextColumn get notes => text().nullable()();
  TextColumn get identifiers => text().map(const IdentifierListConverter())();
  TextColumn get coverUrl => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  TextColumn get cacheSource => text()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();

  @override
  Set<Column> get primaryKey => {discogsReleaseId};
}

@DataClassName('RetryActionRow')
class RetryActions extends Table {
  TextColumn get id => text()();
  TextColumn get actionType => text().map(const RetryActionTypeConverter())();
  TextColumn get entityType =>
      text().map(const RetryActionEntityTypeConverter())();
  TextColumn get entityId => text()();
  TextColumn get safeErrorMessage => text()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptedAt => dateTime().nullable()();
  IntColumn get attemptCount => integer()();
  TextColumn get status => text().map(const RetryActionStatusConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ImportExportJobRow')
class ImportExportJobs extends Table {
  TextColumn get id => text()();
  TextColumn get jobType => text().map(const ImportExportJobTypeConverter())();
  TextColumn get source => text()();
  TextColumn get target => text()();
  TextColumn get status => text().map(const ImportExportStatusConverter())();
  IntColumn get totalItems => integer().nullable()();
  IntColumn get validItems => integer().nullable()();
  IntColumn get skippedItems => integer().nullable()();
  IntColumn get failedItems => integer().nullable()();
  TextColumn get safeErrorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores per-row results for an import/export job.
/// [resultType] is 'valid', 'skipped', or 'failed' and determines which
/// payload column is populated.
@DataClassName('ImportExportRowResultRow')
class ImportExportRowResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobId => text()();
  TextColumn get resultType => text()();
  IntColumn get rowIndex => integer()();
  TextColumn get description => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get safeErrorMessage => text().nullable()();
}

class SavedSearchTypeConverter extends TypeConverter<SavedSearchType, String> {
  const SavedSearchTypeConverter();

  @override
  SavedSearchType fromSql(String fromDb) =>
      SavedSearchType.values.byName(fromDb);

  @override
  String toSql(SavedSearchType value) => value.name;
}

@DataClassName('SavedSearchRow')
class SavedSearches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text().map(const SavedSearchTypeConverter())();
  TextColumn get payloadJson => text()();
  IntColumn get schemaVersion => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PendingDiscogsDeletionRow')
class PendingDiscogsDeletions extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  IntColumn get discogsReleaseId => integer()();
  IntColumn get discogsInstanceId => integer().nullable()();
  TextColumn get artist => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    CollectionItems,
    WishlistItems,
    CachedReleases,
    RetryActions,
    ImportExportJobs,
    ImportExportRowResults,
    PendingDiscogsDeletions,
    SavedSearches,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(wishlistItems);
      }
      if (from < 3) {
        await m.createTable(cachedReleases);
      }
      if (from < 4) {
        await m.addColumn(collectionItems, collectionItems.syncStatus);
        await m.addColumn(wishlistItems, wishlistItems.syncStatus);
      }
      if (from < 5) {
        await m.createTable(retryActions);
      }
      if (from < 6) {
        await m.createTable(importExportJobs);
        await m.createTable(importExportRowResults);
      }
      if (from < 7) {
        // Cache stores full tracklist + all identifiers; drop and recreate.
        await customStatement('DROP TABLE IF EXISTS cached_releases');
        await m.createTable(cachedReleases);
      }
      if (from < 8) {
        await m.addColumn(retryActions, retryActions.payload);
      }
      if (from < 9) {
        await m.addColumn(collectionItems, collectionItems.discogsInstanceId);
      }
      if (from < 10) {
        await m.createTable(pendingDiscogsDeletions);
      }
      if (from < 11) {
        await m.addColumn(collectionItems, collectionItems.bpm);
        await m.addColumn(collectionItems, collectionItems.musicalKey);
        await m.addColumn(collectionItems, collectionItems.energyLevel);
        await m.addColumn(collectionItems, collectionItems.gigCrates);
      }
      if (from < 12) {
        await m.createTable(savedSearches);
      }
    },
  );
}

LazyDatabase openAppDatabase() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cratewise.db'));
    return NativeDatabase(file);
  });
}
