import 'package:cratewise/application/use_cases/execute_collection_csv_export_use_case.dart';
import 'package:cratewise/domain/models/collection_item.dart';
import 'package:cratewise/domain/models/csv_collection_export_preview.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/infrastructure/csv/collection_csv_mapper.dart';
import 'package:cratewise/infrastructure/csv/csv_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCsvFileWriter implements CsvFileWriter {
  int callCount = 0;
  String? lastFilename;
  List<String>? lastHeaders;
  List<List<String>>? lastRows;

  @override
  Future<String> write({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    callCount++;
    lastFilename = filename;
    lastHeaders = headers;
    lastRows = rows;
    return '/tmp/$filename';
  }
}

class _ThrowingCsvFileWriter implements CsvFileWriter {
  @override
  Future<String> write({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) => Future.error(Exception('write error'));
}

class _FakeJobRepository implements ImportExportJobRepository {
  final List<ImportExportJob> added = [];
  final List<ImportExportJob> updated = [];

  @override
  Future<void> add(ImportExportJob job) async => added.add(job);

  @override
  Future<void> update(ImportExportJob job) async => updated.add(job);

  @override
  Future<ImportExportJob?> getById(String id) async => null;

  @override
  Future<List<ImportExportJob>> getRecent({int limit = 20}) async => [];

  @override
  Future<void> remove(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CollectionItem _item(String id) => CollectionItem(
  id: id,
  discogsReleaseId: 1,
  artist: 'Artist',
  title: 'Title',
  mediaCondition: RecordCondition.notSet,
  sleeveCondition: RecordCondition.notSet,
  tags: [],
  syncStatus: SyncStatus.localOnly,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
);

CsvCollectionExportPreview _preview({int itemCount = 2}) =>
    CsvCollectionExportPreview(
      items: List.generate(itemCount, (i) => _item('item-$i')),
      headers: collectionCsvHeaders,
      sampleRows: const [],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExecuteCollectionCsvExportUseCase', () {
    group('on success', () {
      test('returns ExecuteCollectionCsvExportCompleted', () async {
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result = await uc.execute(_preview());
        expect(result, isA<ExecuteCollectionCsvExportCompleted>());
      });

      test('completed result rowCount matches preview rowCount', () async {
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview(itemCount: 5))
                as ExecuteCollectionCsvExportCompleted;
        expect(result.rowCount, 5);
      });

      test(
        'completed result filename starts with collection_export_',
        () async {
          final uc = ExecuteCollectionCsvExportUseCase(
            jobRepository: _FakeJobRepository(),
            fileWriter: _FakeCsvFileWriter(),
            onShare: (_) async {},
          );
          final result =
              await uc.execute(_preview())
                  as ExecuteCollectionCsvExportCompleted;
          expect(result.filename, startsWith('collection_export_'));
        },
      );

      test('completed result filename ends with .csv', () async {
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview()) as ExecuteCollectionCsvExportCompleted;
        expect(result.filename, endsWith('.csv'));
      });

      test('file writer is called once', () async {
        final writer = _FakeCsvFileWriter();
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: writer,
          onShare: (_) async {},
        );
        await uc.execute(_preview());
        expect(writer.callCount, 1);
      });

      test('file writer receives correct headers', () async {
        final writer = _FakeCsvFileWriter();
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: writer,
          onShare: (_) async {},
        );
        await uc.execute(_preview());
        expect(writer.lastHeaders, collectionCsvHeaders);
      });

      test('file writer receives one row per item', () async {
        final writer = _FakeCsvFileWriter();
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: writer,
          onShare: (_) async {},
        );
        await uc.execute(_preview(itemCount: 4));
        expect(writer.lastRows?.length, 4);
      });

      test('share callback is invoked', () async {
        var shareInvoked = false;
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async => shareInvoked = true,
        );
        await uc.execute(_preview());
        expect(shareInvoked, isTrue);
      });

      test('job is added and updated to completed', () async {
        final repo = _FakeJobRepository();
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: repo,
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        await uc.execute(_preview());
        expect(repo.added.length, 1);
        expect(repo.updated.length, 1);
        expect(repo.updated.last.status, ImportExportStatus.completed);
      });

      test(
        'completed result does not contain token or secret strings',
        () async {
          final uc = ExecuteCollectionCsvExportUseCase(
            jobRepository: _FakeJobRepository(),
            fileWriter: _FakeCsvFileWriter(),
            onShare: (_) async {},
          );
          final result =
              await uc.execute(_preview())
                  as ExecuteCollectionCsvExportCompleted;
          expect(result.filename.toLowerCase(), isNot(contains('token')));
          expect(result.filename.toLowerCase(), isNot(contains('secret')));
        },
      );

      test('idGenerator is used to set jobId', () async {
        final repo = _FakeJobRepository();
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: repo,
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
          idGenerator: () => 'fixed-id',
        );
        final result =
            await uc.execute(_preview()) as ExecuteCollectionCsvExportCompleted;
        expect(result.jobId, 'fixed-id');
        expect(repo.added.first.id, 'fixed-id');
      });
    });

    group('on file writer error', () {
      test('returns ExecuteCollectionCsvExportFailed', () async {
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _ThrowingCsvFileWriter(),
          onShare: (_) async {},
        );
        final result = await uc.execute(_preview());
        expect(result, isA<ExecuteCollectionCsvExportFailed>());
      });

      test('failure message is safe — no token or secret', () async {
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _ThrowingCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview()) as ExecuteCollectionCsvExportFailed;
        expect(result.safeMessage.toLowerCase(), isNot(contains('token')));
        expect(result.safeMessage.toLowerCase(), isNot(contains('secret')));
        expect(result.safeMessage, isNotEmpty);
      });

      test('job is updated to failed on file write error', () async {
        final repo = _FakeJobRepository();
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: repo,
          fileWriter: _ThrowingCsvFileWriter(),
          onShare: (_) async {},
        );
        await uc.execute(_preview());
        expect(repo.updated.last.status, ImportExportStatus.failed);
      });
    });

    group('on empty collection', () {
      test('returns completed with rowCount 0', () async {
        final uc = ExecuteCollectionCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview(itemCount: 0))
                as ExecuteCollectionCsvExportCompleted;
        expect(result.rowCount, 0);
      });
    });
  });
}
