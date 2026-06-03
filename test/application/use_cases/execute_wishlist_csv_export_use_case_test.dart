import 'package:cratewise/application/use_cases/execute_wishlist_csv_export_use_case.dart';
import 'package:cratewise/domain/models/csv_wishlist_export_preview.dart';
import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:cratewise/domain/models/sync_status.dart';
import 'package:cratewise/domain/models/wishlist_item.dart';
import 'package:cratewise/domain/repositories/import_export_job_repository.dart';
import 'package:cratewise/infrastructure/csv/csv_file_writer.dart';
import 'package:cratewise/infrastructure/csv/wishlist_csv_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCsvFileWriter implements CsvFileWriter {
  int callCount = 0;

  @override
  Future<String> write({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    callCount++;
    return '/tmp/$filename';
  }
}

class _ThrowingCsvFileWriter implements CsvFileWriter {
  @override
  Future<String> write({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) =>
      Future.error(Exception('write error'));
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

WishlistItem _item(String id) => WishlistItem(
      id: id,
      discogsReleaseId: 1,
      artist: 'Artist',
      title: 'Title',
      priority: WishlistPriority.low,
      syncStatus: SyncStatus.localOnly,
      createdAt: DateTime.utc(2024),
      updatedAt: DateTime.utc(2024),
    );

CsvWishlistExportPreview _preview({int itemCount = 2}) =>
    CsvWishlistExportPreview(
      items: List.generate(itemCount, (i) => _item('item-$i')),
      headers: wishlistCsvHeaders,
      sampleRows: const [],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExecuteWishlistCsvExportUseCase', () {
    group('on success', () {
      test('returns ExecuteWishlistCsvExportCompleted', () async {
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result = await uc.execute(_preview());
        expect(result, isA<ExecuteWishlistCsvExportCompleted>());
      });

      test('completed result rowCount matches preview rowCount', () async {
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview(itemCount: 3)) as ExecuteWishlistCsvExportCompleted;
        expect(result.rowCount, 3);
      });

      test('completed result filename starts with wishlist_export_', () async {
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview()) as ExecuteWishlistCsvExportCompleted;
        expect(result.filename, startsWith('wishlist_export_'));
      });

      test('completed result filename ends with .csv', () async {
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview()) as ExecuteWishlistCsvExportCompleted;
        expect(result.filename, endsWith('.csv'));
      });

      test('share callback is invoked', () async {
        var invoked = false;
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async => invoked = true,
        );
        await uc.execute(_preview());
        expect(invoked, isTrue);
      });

      test('job is added and updated to completed', () async {
        final repo = _FakeJobRepository();
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: repo,
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        await uc.execute(_preview());
        expect(repo.added.length, 1);
        expect(repo.updated.last.status, ImportExportStatus.completed);
      });

      test('completed result contains no token or secret strings', () async {
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _FakeCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview()) as ExecuteWishlistCsvExportCompleted;
        expect(result.filename.toLowerCase(), isNot(contains('token')));
        expect(result.filename.toLowerCase(), isNot(contains('secret')));
      });
    });

    group('on file writer error', () {
      test('returns ExecuteWishlistCsvExportFailed', () async {
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _ThrowingCsvFileWriter(),
          onShare: (_) async {},
        );
        final result = await uc.execute(_preview());
        expect(result, isA<ExecuteWishlistCsvExportFailed>());
      });

      test('failure message is safe — no token or secret', () async {
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: _FakeJobRepository(),
          fileWriter: _ThrowingCsvFileWriter(),
          onShare: (_) async {},
        );
        final result =
            await uc.execute(_preview()) as ExecuteWishlistCsvExportFailed;
        expect(result.safeMessage.toLowerCase(), isNot(contains('token')));
        expect(result.safeMessage.toLowerCase(), isNot(contains('secret')));
        expect(result.safeMessage, isNotEmpty);
      });

      test('job is updated to failed on error', () async {
        final repo = _FakeJobRepository();
        final uc = ExecuteWishlistCsvExportUseCase(
          jobRepository: repo,
          fileWriter: _ThrowingCsvFileWriter(),
          onShare: (_) async {},
        );
        await uc.execute(_preview());
        expect(repo.updated.last.status, ImportExportStatus.failed);
      });
    });
  });
}
