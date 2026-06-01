import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/collection_item.dart';
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

class WishlistPriorityConverter
    extends TypeConverter<WishlistPriority, String> {
  const WishlistPriorityConverter();

  @override
  WishlistPriority fromSql(String fromDb) =>
      WishlistPriority.values.byName(fromDb);

  @override
  String toSql(WishlistPriority value) => value.name;
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
  TextColumn get priority =>
      text().map(const WishlistPriorityConverter())();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [CollectionItems, WishlistItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(wishlistItems);
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
