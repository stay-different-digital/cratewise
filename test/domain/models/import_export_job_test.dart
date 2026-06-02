import 'package:cratewise/domain/models/import_export_job.dart';
import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:cratewise/domain/models/import_export_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 6, 1);
  final updatedAt = DateTime(2026, 6, 2);

  ImportExportJob base() => ImportExportJob(
        id: 'job-1',
        jobType: ImportExportJobType.csvCollectionExport,
        source: 'Local collection',
        target: 'collection_export.csv',
        status: ImportExportStatus.idle,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  group('ImportExportJob', () {
    test('stores all required fields', () {
      final job = base();
      expect(job.id, 'job-1');
      expect(job.jobType, ImportExportJobType.csvCollectionExport);
      expect(job.source, 'Local collection');
      expect(job.target, 'collection_export.csv');
      expect(job.status, ImportExportStatus.idle);
      expect(job.createdAt, createdAt);
      expect(job.updatedAt, updatedAt);
    });

    test('optional fields default to null', () {
      final job = base();
      expect(job.totalItems, isNull);
      expect(job.validItems, isNull);
      expect(job.skippedItems, isNull);
      expect(job.failedItems, isNull);
      expect(job.safeErrorMessage, isNull);
    });

    test('stores all optional fields when provided', () {
      final job = ImportExportJob(
        id: 'job-2',
        jobType: ImportExportJobType.csvCollectionImport,
        source: 'collection.csv',
        target: 'Local collection',
        status: ImportExportStatus.completedWithErrors,
        createdAt: createdAt,
        updatedAt: updatedAt,
        totalItems: 100,
        validItems: 95,
        skippedItems: 3,
        failedItems: 2,
        safeErrorMessage: 'Some rows could not be parsed.',
      );
      expect(job.totalItems, 100);
      expect(job.validItems, 95);
      expect(job.skippedItems, 3);
      expect(job.failedItems, 2);
      expect(job.safeErrorMessage, 'Some rows could not be parsed.');
    });

    group('copyWith', () {
      test('returns identical job when no arguments provided', () {
        final job = base();
        final copy = job.copyWith();
        expect(copy.id, job.id);
        expect(copy.jobType, job.jobType);
        expect(copy.source, job.source);
        expect(copy.target, job.target);
        expect(copy.status, job.status);
        expect(copy.createdAt, job.createdAt);
        expect(copy.updatedAt, job.updatedAt);
      });

      test('updates status', () {
        final job = base().copyWith(status: ImportExportStatus.running);
        expect(job.status, ImportExportStatus.running);
      });

      test('updates item counts', () {
        final job = base().copyWith(
          totalItems: 50,
          validItems: 48,
          skippedItems: 1,
          failedItems: 1,
        );
        expect(job.totalItems, 50);
        expect(job.validItems, 48);
        expect(job.skippedItems, 1);
        expect(job.failedItems, 1);
      });

      test('clears safeErrorMessage when clearSafeErrorMessage is true', () {
        final job = ImportExportJob(
          id: 'job-3',
          jobType: ImportExportJobType.csvCollectionExport,
          source: 'Local collection',
          target: 'export.csv',
          status: ImportExportStatus.failed,
          createdAt: createdAt,
          updatedAt: updatedAt,
          safeErrorMessage: 'An error occurred.',
        );
        final cleared = job.copyWith(clearSafeErrorMessage: true);
        expect(cleared.safeErrorMessage, isNull);
      });

      test('clears item counts individually', () {
        final job = ImportExportJob(
          id: 'job-4',
          jobType: ImportExportJobType.csvCollectionImport,
          source: 'file.csv',
          target: 'Local collection',
          status: ImportExportStatus.running,
          createdAt: createdAt,
          updatedAt: updatedAt,
          totalItems: 10,
          validItems: 8,
          skippedItems: 1,
          failedItems: 1,
        );
        final cleared = job.copyWith(
          clearTotalItems: true,
          clearValidItems: true,
          clearSkippedItems: true,
          clearFailedItems: true,
        );
        expect(cleared.totalItems, isNull);
        expect(cleared.validItems, isNull);
        expect(cleared.skippedItems, isNull);
        expect(cleared.failedItems, isNull);
      });
    });

    test('source and target do not contain tokens', () {
      final job = base();
      expect(job.source.toLowerCase(), isNot(contains('token')));
      expect(job.target.toLowerCase(), isNot(contains('secret')));
    });
  });
}
