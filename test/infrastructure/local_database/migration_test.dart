// Schema migration tests (US-125). When bumping AppDatabase.schemaVersion:
//   dart run drift_dev schema dump lib/infrastructure/local_database/app_database.dart drift_schemas/
//   dart run drift_dev schema generate drift_schemas/ test/infrastructure/local_database/generated_migrations/
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/local_collection_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const latest = 13;

  test('schemaVersion matches the newest dumped schema', () async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    expect(db.schemaVersion, latest);
    await db.close();
  });

  for (var from = 1; from < latest; from++) {
    test('migrates v$from → v$latest', () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, latest);
      await db.close();
    });
  }

  test('a v10 collection row keeps its data after upgrading', () async {
    final schema = await verifier.schemaAt(10);
    schema.rawDatabase.execute(
      "INSERT INTO collection_items (id, discogs_release_id, artist, title, "
      "label, media_condition, sleeve_condition, notes, tags, sync_status, "
      "discogs_instance_id, created_at, updated_at) VALUES ('c-1', 42, "
      "'Miles Davis', 'Kind of Blue', 'Columbia', 'nearMint', 'veryGood', "
      "'first press', '[\"jazz\"]', 'synced', 9001, 1767225600, 1767225600)",
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);

    final item = (await LocalCollectionRepository(db).getAll()).single;
    expect(item.id, 'c-1');
    expect(item.discogsReleaseId, 42);
    expect(item.artist, 'Miles Davis');
    expect(item.label, 'Columbia');
    expect(item.mediaCondition, RecordCondition.nearMint);
    expect(item.notes, 'first press');
    expect(item.tags, ['jazz']);
    expect(item.discogsInstanceId, 9001);
    await db.close();
  });

  // US-165: v13 drops the DJ columns by rebuilding collection_items; every
  // other column of an existing row must survive.
  test('a v12 row with DJ values keeps all other data in v13', () async {
    final schema = await verifier.schemaAt(12);
    schema.rawDatabase.execute(
      "INSERT INTO collection_items (id, discogs_release_id, artist, title, "
      "label, catno, format, country, year, cover_url, media_condition, "
      "sleeve_condition, notes, tags, storage_location, sync_status, "
      "discogs_instance_id, bpm, musical_key, energy_level, gig_crates, "
      "created_at, updated_at) VALUES ('c-2', 77, 'Bonobo', 'Black Sands', "
      "'Ninja Tune', 'ZEN140', 'Vinyl, LP', 'UK', 2010, 'https://x/c.jpg', "
      "'mint', 'nearMint', 'gatefold', '[\"downtempo\"]', 'Shelf B', "
      "'synced', 4242, 122, 'aMinor', 4, '[\"Warmup\"]', 1767225600, "
      "1767312000)",
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);

    final columns = await db
        .customSelect('PRAGMA table_info(collection_items)')
        .get();
    final names = columns.map((c) => c.read<String>('name')).toSet();
    expect(
      names.intersection({'bpm', 'musical_key', 'energy_level', 'gig_crates'}),
      isEmpty,
    );

    final item = (await LocalCollectionRepository(db).getAll()).single;
    expect(item.id, 'c-2');
    expect(item.discogsReleaseId, 77);
    expect(item.artist, 'Bonobo');
    expect(item.title, 'Black Sands');
    expect(item.label, 'Ninja Tune');
    expect(item.catno, 'ZEN140');
    expect(item.format, 'Vinyl, LP');
    expect(item.country, 'UK');
    expect(item.year, 2010);
    expect(item.coverUrl, 'https://x/c.jpg');
    expect(item.mediaCondition, RecordCondition.mint);
    expect(item.sleeveCondition, RecordCondition.nearMint);
    expect(item.notes, 'gatefold');
    expect(item.tags, ['downtempo']);
    expect(item.storageLocation, 'Shelf B');
    expect(item.discogsInstanceId, 4242);
    expect(item.createdAt, DateTime.fromMillisecondsSinceEpoch(1767225600000));
    expect(item.updatedAt, DateTime.fromMillisecondsSinceEpoch(1767312000000));
    await db.close();
  });
}
