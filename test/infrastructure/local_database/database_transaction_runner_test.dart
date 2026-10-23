import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/infrastructure/local_database/app_database.dart';
import 'package:cratewise/infrastructure/local_database/database_transaction_runner.dart';
import 'package:cratewise/infrastructure/local_database/local_collection_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionItem _item(String id) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: 'A',
  title: 'T',
  mediaCondition: RecordCondition.veryGoodPlus,
  sleeveCondition: RecordCondition.veryGood,
  tags: const [],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  test('an exception inside run() rolls back every write', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = LocalCollectionRepository(db);

    await expectLater(
      DatabaseTransactionRunner(db).run(() async {
        await repo.add(_item('a'));
        await repo.add(_item('b'));
        throw StateError('boom');
      }),
      throwsStateError,
    );

    expect(await repo.getAll(), isEmpty);
    await db.close();
  });
}
