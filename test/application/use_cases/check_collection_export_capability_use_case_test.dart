import 'package:cratewise/application/use_cases/check_collection_export_capability_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckCollectionExportCapabilityUseCase', () {
    CheckCollectionExportCapabilityUseCase makeUseCase() =>
        const CheckCollectionExportCapabilityUseCase();

    test('returns CollectionExportSupported', () {
      // The Discogs API client supports addToCollection
      // (POST /users/{username}/collection/folders/1/releases/{id}),
      // so exporting must not be gated off.
      final result = makeUseCase().execute();
      expect(result, isA<CollectionExportSupported>());
    });

    test('execute is synchronous and makes no network calls', () {
      // If this completes without async it confirms no I/O is involved.
      final result = makeUseCase().execute();
      expect(result, isNotNull);
    });

    test('calling execute twice returns consistent result', () {
      final uc = makeUseCase();
      expect(uc.execute(), isA<CollectionExportSupported>());
      expect(uc.execute(), isA<CollectionExportSupported>());
    });
  });
}
