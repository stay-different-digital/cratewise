import 'package:cratewise/domain/models/import_export_job_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportExportJobType', () {
    test('has all eight expected values', () {
      expect(
        ImportExportJobType.values,
        unorderedEquals([
          ImportExportJobType.importCollectionFromDiscogs,
          ImportExportJobType.importWishlistFromDiscogs,
          ImportExportJobType.exportCollectionToDiscogs,
          ImportExportJobType.exportWishlistToDiscogs,
          ImportExportJobType.csvCollectionExport,
          ImportExportJobType.csvWishlistExport,
          ImportExportJobType.csvCollectionImport,
          ImportExportJobType.csvWishlistImport,
        ]),
      );
    });

    test('every value has a non-empty label', () {
      for (final type in ImportExportJobType.values) {
        expect(type.label, isNotEmpty, reason: '${type.name} label is empty');
      }
    });

    test('switch is exhaustive over all values', () {
      for (final type in ImportExportJobType.values) {
        final label = switch (type) {
          ImportExportJobType.importCollectionFromDiscogs =>
            'importCollectionFromDiscogs',
          ImportExportJobType.importWishlistFromDiscogs =>
            'importWishlistFromDiscogs',
          ImportExportJobType.exportCollectionToDiscogs =>
            'exportCollectionToDiscogs',
          ImportExportJobType.exportWishlistToDiscogs =>
            'exportWishlistToDiscogs',
          ImportExportJobType.csvCollectionExport => 'csvCollectionExport',
          ImportExportJobType.csvWishlistExport => 'csvWishlistExport',
          ImportExportJobType.csvCollectionImport => 'csvCollectionImport',
          ImportExportJobType.csvWishlistImport => 'csvWishlistImport',
        };
        expect(label, isNotEmpty);
      }
    });

    test('labels contain expected keywords', () {
      expect(
        ImportExportJobType.importCollectionFromDiscogs.label,
        contains('collection'),
      );
      expect(
        ImportExportJobType.csvWishlistExport.label,
        contains('CSV'),
      );
      expect(
        ImportExportJobType.exportCollectionToDiscogs.label,
        contains('Discogs'),
      );
    });

    test('labels do not contain tokens or secrets', () {
      for (final type in ImportExportJobType.values) {
        expect(type.label.toLowerCase(), isNot(contains('token')));
        expect(type.label.toLowerCase(), isNot(contains('secret')));
        expect(type.label.toLowerCase(), isNot(contains('key')));
      }
    });
  });
}
